shader_type spatial;

render_mode cull_disabled, depth_test_disable, unshaded;

varying flat mat4 model_view_matrix;
uniform vec3 cam_pos;
uniform bool use_shadow = true;

uniform sampler2D screen_texture : hint_albedo;
uniform sampler2D screenDepth;
uniform float energy = 20;
uniform float reflectivity = 1;
uniform bool use_sky_light = true;
uniform float min_sky_light = 0;
uniform float max_sky_light = 1;

uniform vec3 sun_dir = vec3(0, 0, 1);

// first, lets define some constants to use (planet radius, position, and scattering coefficients)
uniform vec3 PLANET_POS = vec3(0.0); /* the position of the planet */
uniform float PLANET_RADIUS =  6378137.0; /* radius of the planet */
uniform float ATMOS_RADIUS = 6478137.0; /* radius of the atmosphere */
uniform float height = 8848;
// scattering coeffs
uniform vec3 RAY_BETA = vec3(5.5e-6, 13.0e-6, 22.4e-6); /* rayleigh, affects the color of the sky */
//uniform vec3 ray_factor = vec3(2.089, 1.147, 0.759); //阴天
uniform vec4 ray_factor:hint_color = vec4(1, 1, 1, 1); 
uniform vec3 MIE_BETA = vec3(21e-6); /* mie, affects the color of the blob around the sun */
uniform float mie_factor = 1.0;


uniform vec4 AMBIENT_BETA :hint_color = vec4(0.0); /* ambient, affects the scattering color when there is no lighting from the sun */
uniform vec3 ABSORPTION_BETA =  vec3(2.04e-5, 4.97e-5, 1.95e-6); /* what color gets absorbed by the atmosphere (Due to things like ozone) */
uniform vec4 absorption_factor = vec4(1, 1, 1, 1);
uniform float G = 0.97; /* mie scattering direction, or how big the blob around the sun is */
// and the heights (how far to go up before the scattering has no effect)
uniform float HEIGHT_RAY =  8000.0; /* rayleigh height */
uniform float HEIGHT_MIE = 1.2e3; /* and mie */
uniform float HEIGHT_ABSORPTION =  30e3; /* at what height the absorption is at it's maximum */
uniform float ABSORPTION_FALLOFF = 4e3; /* how much the absorption decreases the further away it gets from the maximum height */
// and the steps (more looks better, but is slower)
uniform int PRIMARY_STEPS = 16; /* primary steps, affects quality the most */
uniform int LIGHT_STEPS  = 4; /* light steps, how much steps in the light direction are taken */
uniform float particles_density_i = 1.0;
uniform float particles_density_l = 1.0;

varying mat4 modelViewMatrix_inv;

mat4 get_projection_matrix(float fov, float aspect, float near, float far)
{
	float mat11 = 1.0 / (tan(fov / 2.0) * aspect);
	float mat22 = 1.0 / tan(fov / 2.0);
	float mat33 = (near + far) / (near - far);
	float mat34 = 2.0 * near * far / (near - far);
	mat4 projection_matrix = mat4(
		vec4(mat11, 0, 0, 0),
		vec4(0, mat22, 0, 0),
		vec4(0, 0, mat33, -1),
		vec4(0, 0, mat34, 0)
	);
	return projection_matrix;
}
mat4 get_inv_camera_matrix(vec3 up, vec3 direction, vec3 camera_position) //世界空间到视图空间矩阵
{
	vec3 N = normalize(-direction);
	vec3 U = normalize(cross(up, N));
	vec3 V = normalize(cross(N, U));
	mat4 inv_camera_matrix = mat4(
		vec4(U.x, V.x, N.x, 0),
		vec4(U.y, V.y, N.y, 0),
		vec4(U.z, V.z, N.z, 0),
		vec4(-dot(U, camera_position), -dot(V, camera_position), -dot(N, camera_position), 1)
	);
	return inv_camera_matrix;
}
vec3 ACESFilm( vec3 x )
{
    float tA = 2.51;
    float tB = 0.03;
    float tC = 2.43;
    float tD = 0.59;
    float tE = 0.14;
    return clamp((x*(tA*x+tB))/(x*(tC*x+tD)+tE),0.0,1.0);
}


vec3 getCameraPos(mat4 inv_camera_mat)
{
	vec3 R = inv_camera_mat[0].xyz;
	vec3 U = inv_camera_mat[1].xyz;
	vec3 V = inv_camera_mat[2].xyz;
	vec3 W = inv_camera_mat[3].xyz;
	
	mat3 ruv_mat = mat3(R, U, V);
	mat3 inv_ruv_mat = inverse(ruv_mat);
	vec3 pos = inv_ruv_mat * W;
	return -pos;
}


vec3 calculate_scattering(
	vec3 start, 				// the start of the ray (the camera position)
    vec3 dir, 					// the direction of the ray (the camera vector)
    float max_dist, 			// the maximum distance the ray can travel (because something is in the way, like an object)
    vec3 scene_color,			// the color of the scene
    vec3 light_dir, 			// the direction of the light
    vec3 light_intensity,		// how bright the light is, affects the brightness of the atmosphere
    vec3 planet_position, 		// the position of the planet
    float planet_radius, 		// the radius of the planet
    float atmo_radius, 			// the radius of the atmosphere
    vec3 beta_ray, 				// the amount rayleigh scattering scatters the colors (for earth: causes the blue atmosphere)
    vec3 beta_mie, 				// the amount mie scattering scatters colors
    vec3 beta_absorption,   	// how much air is absorbed
    vec3 beta_ambient,			// the amount of scattering that always occurs, cna help make the back side of the atmosphere a bit brighter
    float g, 					// the direction mie scatters the light in (like a cone). closer to -1 means more towards a single direction
    float height_ray, 			// how high do you have to go before there is no rayleigh scattering?
    float height_mie, 			// the same, but for mie
    float height_absorption,	// the height at which the most absorption happens
    float absorption_falloff,	// how fast the absorption falls off from the absorption height
    int steps_i, 				// the amount of steps along the 'primary' ray, more looks better but slower
    int steps_l 				// the amount of steps along the light ray, more looks better but slower
) {
	beta_mie = beta_mie * mie_factor;
	beta_absorption = beta_absorption * absorption_factor.xyz; 
    // add an offset to the camera position, so that the atmosphere is in the correct position
    start -= planet_position;
    // calculate the start and end position of the ray, as a distance along the ray
    // we do this with a ray sphere intersect
    float a = dot(dir, dir);
    float b = 2.0 * dot(dir, start);
    float c = dot(start, start) - (atmo_radius * atmo_radius);
    float d = (b * b) - 4.0 * a * c;
    
    // stop early if there is no intersect
    if (d < 0.0) return scene_color;
    
    // calculate the ray length
    vec2 ray_length = vec2(
        max((-b - sqrt(d)) / (2.0 * a), 0.0),
        min((-b + sqrt(d)) / (2.0 * a), max_dist)
    );
    
    // if the ray did not hit the atmosphere, return a black color
    if (ray_length.x > ray_length.y) return scene_color;
    // prevent the mie glow from appearing if there's an object in front of the camera
    bool allow_mie = max_dist > ray_length.y;
    // make sure the ray is no longer than allowed
    ray_length.y = min(ray_length.y, max_dist);
    ray_length.x = max(ray_length.x, 0.0);
    // get the step size of the ray
    float step_size_i = (ray_length.y - ray_length.x) / float(steps_i);
    
    // next, set how far we are along the ray, so we can calculate the position of the sample
    // if the camera is outside the atmosphere, the ray should start at the edge of the atmosphere
    // if it's inside, it should start at the position of the camera
    // the min statement makes sure of that
    float ray_pos_i = ray_length.x + step_size_i * 0.5;
    
    // these are the values we use to gather all the scattered light
    vec3 total_ray = vec3(0.0); // for rayleigh
    vec3 total_mie = vec3(0.0); // for mie
    
    // initialize the optical depth. This is used to calculate how much air was in the ray
    vec3 opt_i = vec3(0.0);
    
    // also init the scale height, avoids some vec2's later on
    vec2 scale_height = vec2(height_ray, height_mie);
    
    // Calculate the Rayleigh and Mie phases.
    // This is the color that will be scattered for this ray
    // mu, mumu and gg are used quite a lot in the calculation, so to speed it up, precalculate them
    float mu = dot(dir, light_dir);
    float mumu = mu * mu;
    float gg = g * g;
    float phase_ray = 3.0 / (50.2654824574 /* (16 * pi) */) * (1.0 + mumu);
    float phase_mie = allow_mie ? 3.0 / (25.1327412287 /* (8 * pi) */) * ((1.0 - gg) * (mumu + 1.0)) / (pow(1.0 + gg - 2.0 * mu * g, 1.5) * (2.0 + gg)) : 0.0;
    
    // now we need to sample the 'primary' ray. this ray gathers the light that gets scattered onto it
    for (int i = 0; i < steps_i; ++i) {
        
        // calculate where we are along this ray
        vec3 pos_i = start + dir * ray_pos_i;
        
        // and how high we are above the surface
        float height_i = length(pos_i) - planet_radius;
        
        // now calculate the density of the particles (both for rayleigh and mie)
        vec3 density = vec3(exp(-height_i / scale_height ) * particles_density_i, 0);
        
        // and the absorption density. this is for ozone, which scales together with the rayleigh, 
        // but absorbs the most at a specific height, so use the sech function for a nice curve falloff for this height
        // clamp it to avoid it going out of bounds. This prevents weird black spheres on the night side
        float denom = (height_absorption - height_i) / absorption_falloff;
        density.z = (1.0 / (denom * denom + 1.0)) * density.x;
        
        // multiply it by the step size here
        // we are going to use the density later on as well
        density *= step_size_i;
        
        // Add these densities to the optical depth, so that we know how many particles are on this ray.
        opt_i += density;
        
        // Calculate the step size of the light ray.
        // again with a ray sphere intersect
        // a, b, c and d are already defined
        a = dot(light_dir, light_dir);
        b = 2.0 * dot(light_dir, pos_i);
        c = dot(pos_i, pos_i) - (atmo_radius * atmo_radius);
        d = (b * b) - 4.0 * a * c;

        // no early stopping, this one should always be inside the atmosphere
        // calculate the ray length
        float step_size_l = (-b + sqrt(d)) / (2.0 * a * float(steps_l));

        // and the position along this ray
        // this time we are sure the ray is in the atmosphere, so set it to 0
        float ray_pos_l = step_size_l * 0.5;

        // and the optical depth of this ray
        vec3 opt_l = vec3(0.0);
            
        // now sample the light ray
        // this is similar to what we did before
        for (int l = 0; l < steps_l; ++l) {

            // calculate where we are along this ray
            vec3 pos_l = pos_i + light_dir * ray_pos_l;

            // the heigth of the position
            float height_l = length(pos_l) - planet_radius;

            // calculate the particle density, and add it
            // this is a bit verbose
            // first, set the density for ray and mie
            vec3 density_l = vec3(exp(-height_l / scale_height) * particles_density_l, 0.0);
            
            // then, the absorption
            float denom_l = (height_absorption - height_l) / absorption_falloff;
            density_l.z = (1.0 / (denom_l * denom_l + 1.0)) * density_l.x;
            
            // multiply the density by the step size
            density_l *= step_size_l;
            
            // and add it to the total optical depth
            opt_l += density_l;
            
            // and increment where we are along the light ray.
            ray_pos_l += step_size_l;
            
        }
        
        // Now we need to calculate the attenuation
        // this is essentially how much light reaches the current sample point due to scattering
        vec3 attn = exp(-beta_ray * (opt_i.x + opt_l.x) - beta_mie * (opt_i.y + opt_l.y) 
		- beta_absorption * (opt_i.z + opt_l.z)
		);

        // accumulate the scattered light (how much will be scattered towards the camera)
        total_ray += density.x * attn;
        total_mie += density.y * attn;

        // and increment the position on this ray
        ray_pos_i += step_size_i;
    	
    }
    
    // calculate how much light can pass through the atmosphere
    vec3 opacity = exp(-(beta_mie * opt_i.y + beta_ray * opt_i.x + beta_absorption * opt_i.z));
    
	// calculate and return the final color
    return (
        	phase_ray * beta_ray * total_ray // rayleigh color
       		+ phase_mie * beta_mie * total_mie // mie
            + opt_i.x * beta_ambient // and ambient
    ) * light_intensity 
	+ scene_color * opacity
	; // now make sure the background is rendered correctly
}

/*
A ray-sphere intersect
This was previously used in the atmosphere as well, but it's only used for the planet intersect now, since the atmosphere has this
ray sphere intersect built in
*/

vec2 ray_sphere_intersect(
    vec3 start, // starting position of the ray
    vec3 dir, // the direction of the ray
    float radius // and the sphere radius
) {
    // ray-sphere intersection that assumes
    // the sphere is centered at the origin.
    // No intersection when result.x > result.y
    float a = dot(dir, dir);
    float b = 2.0 * dot(dir, start);
    float c = dot(start, start) - (radius * radius);
    float d = (b*b) - 4.0*a*c;
    if (d < 0.0) return vec2(1e5,-1e5);
    return vec2(
        (-b - sqrt(d))/(2.0*a),
        (-b + sqrt(d))/(2.0*a)
    );
}

/*
To make the planet we're rendering look nicer, we implemented a skylight function here

Essentially it just takes a sample of the atmosphere in the direction of the surface normal
*/
vec3 skylight(vec3 sample_pos, vec3 surface_normal, vec3 light_dir, vec3 background_col) {

    // slightly bend the surface normal towards the light direction
    //surface_normal = normalize(mix(surface_normal, light_dir, 0.6));
    vec3 RAY_BETA0 = RAY_BETA * ray_factor.xyz;
    // and sample the atmosphere
    return calculate_scattering(
    	sample_pos,						// the position of the camera
        surface_normal, 				// the camera vector (ray direction of this pixel)
        3.0 * ATMOS_RADIUS, 			// max dist, since nothing will stop the ray here, just use some arbitrary value
        background_col,					// scene color, just the background color here
        light_dir,						// light direction
        vec3(energy),						// light intensity, 40 looks nice
        PLANET_POS,						// position of the planet
        PLANET_RADIUS,                  // radius of the planet in meters
        ATMOS_RADIUS,                   // radius of the atmosphere in meters
        RAY_BETA0,						// Rayleigh scattering coefficient
        MIE_BETA,                       // Mie scattering coefficient
        ABSORPTION_BETA,                // Absorbtion coefficient
        AMBIENT_BETA.xyz,					// ambient scattering, turned off for now. This causes the air to glow a bit when no light reaches it
        G,                          	// Mie preferred scattering direction
        HEIGHT_RAY,                     // Rayleigh scale height
        HEIGHT_MIE,                     // Mie scale height
        HEIGHT_ABSORPTION,				// the height at which the most absorption happens
        ABSORPTION_FALLOFF,				// how fast the absorption falls off from the absorption height
        LIGHT_STEPS, 					// steps in the ray direction
        LIGHT_STEPS 					// steps in the light direction
    );
}

/*
The following function returns the scene color and depth 
(the color of the pixel without the atmosphere, and the distance to the surface that is visible on that pixel)

in this case, the function renders a green sphere on the place where the planet should be
color is in .xyz, distance in .w

I won't explain too much about how this works, since that's not the aim of this shader
*/
vec4 render_scene(vec3 pos, vec3 dir, vec3 light_dir, sampler2D tex, vec2 uv, vec3 piexlPos) {
    
    // the color to use, w is the scene depth
    vec4 color = vec4(0.0, 0.0, 0.0, 1e12);
    
    // add a sun, if the angle between the ray direction and the light direction is small enough, color the pixels white
    color.xyz = vec3(dot(dir, light_dir) > 0.9998 ? 1.0 : 0.0);

    // get where the ray intersects the planet
    vec2 planet_intersect = ray_sphere_intersect(pos - PLANET_POS, dir, PLANET_RADIUS); 
    // if the ray hit the planet, set the max distance to that ray
	if(length(cam_pos) >= PLANET_RADIUS + height)
	{
		if (0.0 < planet_intersect.y) {
	    	color.w = max(planet_intersect.x, 0.0);

	        // sample position, where the pixel is
	        vec3 sample_pos = pos + (dir * planet_intersect.x) - PLANET_POS;

	        // and the surface normal
	        vec3 surface_normal = normalize(sample_pos);

	        // get the color of the sphere
	        color.xyz = texture(tex, uv).xyz;
			color.xyz = mix(pow((color.rgb + vec3(0.055)) * (1.0 / (1.0 + 0.055)),vec3(2.4)),color.rgb * (1.0 / 12.92),lessThan(color.rgb,vec3(0.04045)));
	        // get wether this point is shadowed, + how much light scatters towards the camera according to the lommel-seelinger law
	       
			if(use_shadow)
			{
				vec3 N = surface_normal;
	        	vec3 V = -dir;
	        	vec3 L = light_dir;
	        	float dotNV = max(1e-6, dot(N, V));
	        	float dotNL = max(1e-6, dot(N, L));
	        	float shadow = dotNL / (dotNL + dotNV);
				color.xyz *= shadow * reflectivity;
			}
	        // apply the shadow
	        else
			{
				color.xyz *= reflectivity;
			}
			
	        // apply skylight
			if(use_sky_light)
			{
	        	color.xyz += clamp(skylight(sample_pos, surface_normal, light_dir, vec3(10.0)) * color.xyz, min_sky_light, max_sky_light);
			}
//	        color.xyz += clamp(skylight(sample_pos, surface_normal, light_dir, vec3(10.0)) * color.xyz, 0.0, 1.0);
    	}
	}
	else
	{
		float dis = length(piexlPos - cam_pos);
		if(true)
//		if(dis < 100000.0)
		{
			color.w = max(dis, 0.0);

	        // sample position, where the pixel is
	        vec3 sample_pos = piexlPos;

	        // and the surface normal
	        vec3 surface_normal = normalize(sample_pos);

	        // get the color of the sphere
	        color.xyz = texture(tex, uv).xyz;
			color.xyz = mix(pow((color.rgb + vec3(0.055)) * (1.0 / (1.0 + 0.055)),vec3(2.4)),color.rgb * (1.0 / 12.92),lessThan(color.rgb,vec3(0.04045)));
	        //color.xyz = backgroungcolor.xyz;
	        // get wether this point is shadowed, + how much light scatters towards the camera according to the lommel-seelinger law
	       
		
			if(use_shadow)
			{
				vec3 N = surface_normal;
	        	vec3 V = -dir;
	        	vec3 L = light_dir;
	        	float dotNV = max(1e-6, dot(N, V));
	        	float dotNL = max(1e-6, dot(N, L));
	        	float shadow = dotNL / (dotNL + dotNV);
				color.xyz *= shadow * reflectivity;
			}
	        // apply the shadow
	        else
			{
				color.xyz *= reflectivity;
			}
	        // apply the shadow
//	        color.xyz *= shadow * reflectivity;
//			color.xyz *=  reflectivity;
//			color.xyz *= 2.0;
	        // apply skylight
			if(use_sky_light)
			{
	        	color.xyz += clamp(skylight(sample_pos, surface_normal, light_dir, vec3(10.0)) * color.xyz, min_sky_light, max_sky_light);				
			}
//	        color.xyz += clamp(skylight(sample_pos, surface_normal, light_dir, vec3(10.0)) * color.xyz, 0.0, 1.0);
			
		}
//		else
//		{
//			if (0.0 < planet_intersect.y) {
//				color.w = max(planet_intersect.x, 0.0);
//
//		        // sample position, where the pixel is
//		        vec3 sample_pos = pos + (dir * planet_intersect.x) - PLANET_POS;
//
//		        // and the surface normal
//		        vec3 surface_normal = normalize(sample_pos);
//
//		        // get the color of the sphere
//		        color.xyz = texture(tex, uv).xyz;
//				color.xyz = mix(pow((color.rgb + vec3(0.055)) * (1.0 / (1.0 + 0.055)),vec3(2.4)),color.rgb * (1.0 / 12.92),lessThan(color.rgb,vec3(0.04045)));
//		        //color.xyz = backgroungcolor.xyz;
//		        // get wether this point is shadowed, + how much light scatters towards the camera according to the lommel-seelinger law
//		        vec3 N = surface_normal;
//		        vec3 V = -dir;
//		        vec3 L = light_dir;
//		        float dotNV = max(1e-6, dot(N, V));
//		        float dotNL = max(1e-6, dot(N, L));
//		        float shadow = dotNL / (dotNL + dotNV);
//				if(shadow < 0.1) //解决地平线上下亮度不一致
//				{
//					shadow = 0.1;
//				}
//
//		        // apply the shadow
//		        color.xyz *= shadow * reflectivity;
//
//		        // apply skylight
//		        color.xyz += clamp(skylight(sample_pos, surface_normal, light_dir, vec3(10.0)) * color.xyz, 0.0, 1.0);
//			}
//		}
	}
	
    
    
	return color;
}




/*
Finally, draw the atmosphere to screen

we first get the camera vector and position, as well as the light dir
*/

vec3 depthToWorld(sampler2D depthTexture, vec2 screenUV, mat4 invProjectMatrix, mat4 cameraMatrix)
{
	float depth = texture(depthTexture, screenUV).x;
	vec3 ndc = vec3(screenUV, depth) * 2.0 - 1.0;
	vec4 view = invProjectMatrix * vec4(ndc, 1.0);
	vec4 world = cameraMatrix * vec4(view);
	vec3 world_pos =  world.xyz / world.w;
	return world_pos;
}



void vertex() {
  POSITION = vec4(VERTEX, 1.0);
  modelViewMatrix_inv = inverse(MODELVIEW_MATRIX);
  model_view_matrix = CAMERA_MATRIX*MODELVIEW_MATRIX;
}

void fragment() {
//	ALBEDO = texture(screenTexture, SCREEN_UV).xyz;

	vec3 RAY_BETA0 = RAY_BETA * ray_factor.xyz;
    float depth = texture(DEPTH_TEXTURE, SCREEN_UV).x;
	//float depth = texture(DEPTH_TEXTURE, SCREEN_UV).x;
	vec3 ndc = vec3(SCREEN_UV, depth) * 2.0 - 1.0;
	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
//  	view.xyz /= view.w;
	vec4 world = CAMERA_MATRIX * vec4(view);
	vec3 world_pos =  world.xyz / world.w + cam_pos;
//	vec3 world_pos =  depthToWorld(DEPTH_TEXTURE, SCREEN_UV, INV_PROJECTION_MATRIX, CAMERA_MATRIX);
//	vec3 camera_position = vec3(-2611476.21448862, 10600075.0555241, 6598570.08460869);
	vec3 camera_position = cam_pos;
	//vec3 camera_position = getCameraPos(INV_CAMERA_MATRIX);
	// get the camera vector
	vec3 camera_vector = normalize(world_pos - cam_pos);

   // vec3 camera_vector = get_camera_vector(iResolution, fragCoord);


    // get the light direction
    // also base this on the mouse position, that way the time of day can be changed with the mouse
    //vec3 light_dir = normalize(vec3(0.0, cos(-TIME), sin(-TIME))); 
	vec3 light_dir = sun_dir;
//    	normalize(vec3(0.0, cos(iMouse.y * -5.0 / iResolution.y), sin(iMouse.y * -5.0 / iResolution.y)));

//	vec3 light_dir = sunDir;
    // get the scene color and depth, color is in xyz, depth in w
    // replace this with something better if you are using this shader for something else
//    vec4 scene = render_scene(camera_position, camera_vector, light_dir, screenTexture, SCREEN_UV);
	vec4 scene = render_scene(camera_position, camera_vector, light_dir, screen_texture, SCREEN_UV, world_pos);
//	vec4 scene = render_scene(camera_position, camera_vector, light_dir, screenTexture, SCREEN_UV, world_pos);

    // the color of this pixel
    vec3 col = vec3(0.0);//scene.xyz;

    // get the atmosphere color
    col += calculate_scattering(
    	camera_position,				// the position of the camera
        camera_vector, 					// the camera vector (ray direction of this pixel)
        scene.w, 						// max dist, essentially the scene depth
        scene.xyz,						// scene color, the color of the current pixel being rendered
        light_dir,						// light direction
        vec3(energy),						// light intensity, 40 looks nice
        PLANET_POS,						// position of the planet
        PLANET_RADIUS,                  // radius of the planet in meters
        ATMOS_RADIUS,                   // radius of the atmosphere in meters
        RAY_BETA0,						// Rayleigh scattering coefficient
        MIE_BETA,                       // Mie scattering coefficient
        ABSORPTION_BETA,                // Absorbtion coefficient
        AMBIENT_BETA.xyz,					// ambient scattering, turned off for now. This causes the air to glow a bit when no light reaches it
        G,                          	// Mie preferred scattering direction
        HEIGHT_RAY,                     // Rayleigh scale height
        HEIGHT_MIE,                     // Mie scale height
        HEIGHT_ABSORPTION,				// the height at which the most absorption happens
        ABSORPTION_FALLOFF,				// how fast the absorption falls off from the absorption height 
        PRIMARY_STEPS, 					// steps in the ray direction 
        LIGHT_STEPS 					// steps in the light direction
    );

    // apply exposure, removing this makes the brighter colors look ugly
    // you can play around with removing this
    col = 1.0 - exp(-col);

//	col = ACESFilm(col);
    // Output to screen
//	if(col.x > 1.0)
//	ALBEDO = vec3(1, 0, 0);
//	else
//	if(PLANET_RADIUS + 8000.0< length(world_pos))
//	{
//		col = vec3(1, 0.0,0.0);	
//	}


	ALBEDO = col;
//	ALBEDO = scene.xyz;
//	ALPHA = 1.0;
//	ALBEDO = texture(screenDepth, SCREEN_UV).xyz;
//	vec3 cc = texture(screenTexture, SCREEN_UV).xyz;
//	ALBEDO.xyz = mix(pow((cc.rgb + vec3(0.055)) * (1.0 / (1.0 + 0.055)),vec3(2.4)),cc.rgb * (1.0 / 12.92),lessThan(cc.rgb,vec3(0.04045)));
//	ALBEDO = normalize(world_pos);
//	ALPHA = 0.9;
	//ALBEDO = texture(screenTexture, SCREEN_UV).xyz;
	
	

}








