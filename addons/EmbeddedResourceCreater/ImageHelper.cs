using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;
using Godot;

[Tool]
public class ImageHelper : Godot.Reference
{
	bool filter = false;
	bool mipmaps = false;
	int fps = 8;


	public bool Filter { get => filter; set => filter = value; }
	public bool Mipmaps { get => mipmaps; set => mipmaps = value; }
	public int Fps { get => fps; set => fps = value; }

	public AnimatedTexture ConvertGifToAnimatedTexture(byte[] gifBuffer)
	{
		using (MemoryStream gifStream = new MemoryStream(gifBuffer))
		{
			using (System.Drawing.Image gifImage = System.Drawing.Image.FromStream(gifStream))
			{
				var animatedTexture = new AnimatedTexture();
				animatedTexture.Flags = 0;
				animatedTexture.Fps = fps;

				if (filter)
				{
					animatedTexture.Flags |= (int)AnimatedTexture.FlagsEnum.Filter;
				}
				if (mipmaps)
				{
					animatedTexture.Flags |= (int)AnimatedTexture.FlagsEnum.Mipmaps;
				}
				Godot.Image img = new Godot.Image();
				img.Create(gifImage.Width, gifImage.Height, false, Godot.Image.Format.Rgba8);
				FrameDimension dimension = new FrameDimension(gifImage.FrameDimensionsList[0]);
				int frameCount = gifImage.GetFrameCount(dimension);
				animatedTexture.Frames = frameCount;
				byte[][] pngFrames = new byte[frameCount][];

				for (int i = 0; i < frameCount; i++)
				{
					gifImage.SelectActiveFrame(dimension, i);

					using (MemoryStream ms = new MemoryStream())
					{
						gifImage.Save(ms, ImageFormat.Png);
						pngFrames[i] = ms.ToArray();
						img.LoadPngFromBuffer(ms.ToArray());
						var frame = new ImageTexture();
						frame.CreateFromImage(img, 0);
						animatedTexture.SetFrameTexture(i, frame);
						// animatedTexture.Frame255__texture = frame;
						animatedTexture.SetFrameDelay(i, -1.0f / 100.0f);


					}
				}

				return animatedTexture;
			}
		}



	}
	public void SaveAsAnimatedTexture(string gifPath, string outputPath)
	{
		// var animatedTexture = ConvertGifToAnimatedTexture(gifPath);
		// ResourceSaver.Save(outputPath, animatedTexture);

	}
}
