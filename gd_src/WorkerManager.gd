class_name WorkerManager
extends Node

# 最大处理数量
var max_process_count 	:= OS.get_processor_count()
# 全局锁
onready var mutex 				:= Mutex.new()
# 是否退出
var exit_thread 		= false
# 任务环
var worker_rings 		:= []

# 工作者
class Worker:
	# 线程ID
	var idx 			: int
	# 工作线程
	var thread 		 	: Thread
	# 信号
	var semaphore    	: Semaphore
	# 执行的函数名
	var method_name		:= "_do_nothind"
	# 执行的函数参数
	var method_args 	:= []
	# 是否已完成
	var complate		:= true
	# 是否被占用
	var pedding			:= false
	# 持有者
	var owner			: WorkerManager
	# 结果 any 类型
	var result 			
	
	signal on_complate
	signal on_error
	
	func _do_nothind():
		OS.delay_msec(1000)
		print("test")
		return idx	
	
	func _do_io_read(path:String):
		var f = File.new()
		var err = f.open(path,File.READ)
		if err != OK:
			return null
		var buffer = f.get_buffer(f.get_len())
		f.close()
		return buffer
	
	func _do_io_write(path:String,buffer:PoolByteArray)	:
		var f = File.new()
		var err = f.open(path,File.WRITE)
		if err != OK:
			return null
		f.store_buffer(buffer)
		f.close()
		return buffer
		
	func _do_texture_worker(path:String,buffer:PoolByteArray)->RID:
		var err
		var img = Image.new()
		var ext = path.get_extension().to_lower()
		match ext:
			"jpg":
				err = img.load_jpg_from_buffer(buffer)
			"jpeg":
				err = img.load_jpg_from_buffer(buffer)
			"png":
				err = img.load_png_from_buffer(buffer)
			"bmp":
				err = img.load_bmp_from_buffer(buffer)
			"tga":
				err = img.load_tga_from_buffer(buffer)
			"webp":
				err = img.load_webp_from_buffer(buffer)
			_:
				pass
		if err != OK:
			return RID()
		else:
			return VisualServer.texture_create_from_image(img, Texture.FLAG_FILTER)
			
	func _do_gltf_worker(buffer:PoolByteArray,uselight:bool, recalculateNormals:bool):
		var _doc = GLTFDocument.new()
		var _state = GLTFState.new()
		_state.use_in_3dtile = true
		_state.use_light = uselight
		_state.recalculate_normals = recalculateNormals
		var err = _doc.append_from_buffer(buffer, "", _state, 0)
		if err != OK:
			return null
		return _state
	
	func _init():
		thread = Thread.new()
		semaphore = Semaphore.new()
		thread.start(self,"__thread_func")
		pass
		
	func __thread_func():
		while true:
			semaphore.wait()
			
			owner.mutex.lock()
			var should_exit = owner.exit_thread
			owner.mutex.unlock()
			if should_exit:
				break
	
			result = callv(method_name,method_args)
			call_deferred("emit_signal","on_complate",self)
			
			# 仅表示任务完成,但不回收
			owner.mutex.lock()
			complate = true
			owner.mutex.unlock()
	
	# 用户自行结束否则一直持有
	func _finish():
		owner.mutex.lock()
		pedding = false
		owner.mutex.unlock()
			

# 获取空闲的工作者
func _find_free_worker()-> Worker:
	var result:Worker = null
	# 先看是否存在已完成任务
	mutex.lock()
	for w in worker_rings:
		if not w.pedding:
			result = w
			break
	mutex.unlock()
	
	if result != null:
		return result
		
	# 没有的超过最大任务限制的情况下新建工作者并返回		
	mutex.lock()
	var wlen = len(worker_rings)
	if wlen < max_process_count:
		result = Worker.new()
		result.idx = wlen
		result.owner = self
		worker_rings.append(result)
	mutex.unlock()
		
	return result

# 开始任务
func start(mname:String,margs:Array) -> Worker:
	var w 			= _find_free_worker()
	if w == null:
		return null
	# 开启任务
	mutex.lock()
	w.method_name 	= mname
	w.method_args 	= margs
	w.complate 		= false
	w.pedding  		= true
	w.semaphore.post()
	mutex.unlock()
	
	return w
#
#var buffer:PoolByteArray
#func _ready():
#	var f = File.new()
#	f.open("res://icon.png",File.READ)
#	buffer = f.get_buffer(f.get_len())
#
func _exit_tree():
	mutex.lock()
	exit_thread = true
	mutex.unlock()
	
	for w in worker_rings:
		var worker:Worker = w 
		worker.semaphore.post()
		worker.thread.wait_to_finish()
		
#
#func _on_Button_button_down():
#	var worker = start("_do_texture_worker",["res://icon.png",buffer])
#	yield(worker,"on_complate")
#	print(worker.result)
#	worker._finish()
