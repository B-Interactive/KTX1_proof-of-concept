package openfl.display3D._internal;

import haxe.io.Bytes;
import openfl.display3D._internal.ATFGPUFormat;
import openfl.errors.IllegalOperationError;
import openfl.utils.ByteArray;

/**
	This class can read textures from Khronos TeXture v1 format containers.
	You can create such files via tools such as Compressonator:
	`compressonatorcli -fd DXT5 texture.png compressed_texture.ktx`

	To read a texture you need to perform these steps:
	- create a `new KTX1Reader()` instance
	- read the header with `readHeader()`
	- call `readTextures()` and a provide an upload callback

	The KTX v1 specification can be found here:
	<https://registry.khronos.org/KTX/specs/1.0/ktxspec.v1.html>
**/
class KTX1Reader
{
	public var width:Int;
	public var height:Int;
	public var mipCount:Int;
	public var format:String;
	public var glInternalFormat:Int;
	public var glBaseInternalFormat:Int;
	public var atfGPUFormat:Null<ATFGPUFormat>;
	public var hasAlpha:Bool;

	private var mipmapData:Array<
	{
		level:Int,
		face:Int,
		width:Int,
		height:Int,
		size:Int,
		bytes:Bytes
	}>;

	public function new(data:ByteArray, byteArrayOffset:UInt = 0)
	{
		data.position = byteArrayOffset;

		// Check KTX v1 magic number
		var magic = [0xAB, 0x4B, 0x54, 0x58, 0x20, 0x31, 0x31, 0xBB, 0x0D, 0x0A, 0x1A, 0x0A];
		for (i in 0...magic.length)
		{
			if (data[byteArrayOffset + i] != magic[i]) throw new IllegalOperationError("KTX v1 signature not found");
		}

		data.endian = openfl.utils.Endian.LITTLE_ENDIAN;

		// Parse header fields
		data.position = byteArrayOffset + 12;
		var endianness = data.readUnsignedInt();
		if (endianness != 0x04030201) throw new IllegalOperationError("KTX v1: Unexpected endianness");

		var glType = data.readUnsignedInt();
		var glTypeSize = data.readUnsignedInt();
		var glFormat = data.readUnsignedInt();
		glInternalFormat = data.readUnsignedInt(); // actual GLenum value
		glBaseInternalFormat = data.readUnsignedInt();
		width = data.readUnsignedInt();
		height = data.readUnsignedInt();
		var depth = data.readUnsignedInt();
		var arrayElements = data.readUnsignedInt();
		var faces = data.readUnsignedInt();
		mipCount = data.readUnsignedInt();
		var keyValueDataBytes = data.readUnsignedInt();

		if (depth > 0 || arrayElements > 0)
			throw new IllegalOperationError("KTX v1 only supports 2D, non-array textures");

		if (faces != 1 && faces != 6)
			throw new IllegalOperationError("KTX v1 only supports 2D and cubemap textures (faces must be 1 or 6)");

		data.position += keyValueDataBytes;

		atfGPUFormat = ktxGLFormatToATFGPUFormat(glInternalFormat);
		if (atfGPUFormat == null)
			throw new IllegalOperationError("OpenFL KTX v1 support: unsupported GL internal format 0x"
				+ StringTools.hex(glInternalFormat, 4));

		// Determine alpha support following ATF/Texture conventions
		hasAlpha = (
			// DXT5 or ETC2 RGBA, PVRTC2, or other alpha supporting formats
			atfGPUFormat == ATFGPUFormat.DXT && (glInternalFormat == 0x83F3) // DXT5
			|| atfGPUFormat == ATFGPUFormat.ETC2 // ETC2 RGBA (Khronos assigns RGBA=0x9278)
			|| (atfGPUFormat == ATFGPUFormat.PVRTC && glInternalFormat == 0x8C02) // PVRTC RGBA
			// Expand with more alpha formats as added
		);

		// fallback: allow user code to add more heuristics if needed

		// Parse all mipmap levels and faces
		mipmapData = [];
		var levelWidth = width;
		var levelHeight = height;
		for (level in 0...mipCount)
		{
			for (face in 0...faces)
			{
				// Each mip+face starts with imageSize, then image data, then 4-byte alignment
				if (data.position + 4 > data.length) throw new IllegalOperationError('KTX v1: Unexpected EOF reading mipmap imageSize');
				var imageSize = data.readUnsignedInt();

				if (data.position + imageSize > data.length) throw new IllegalOperationError('KTX v1: Unexpected EOF reading mipmap imageData');

				var imageBytes = Bytes.alloc(imageSize);
				data.readBytes(imageBytes, 0, imageSize);

				mipmapData.push({
					level: level,
					face: face,
					width: levelWidth,
					height: levelHeight,
					size: imageSize,
					bytes: imageBytes
				});

				// Advance to next 4-byte boundary (padding, per KTX spec)
				var pad = (4 - (imageSize % 4)) % 4;
				data.position += pad;
			}

			// Next level dimensions (minimum 1)
			levelWidth = Std.int(Math.max(1, levelWidth >> 1));
			levelHeight = Std.int(Math.max(1, levelHeight >> 1));
		}
	}

	static function ktxGLFormatToATFGPUFormat(glInternal:Int):Null<ATFGPUFormat>
	{
		// S3TC
		if (glInternal == 0x83F0 || glInternal == 0x83F1 || glInternal == 0x83F3) return ATFGPUFormat.DXT;
		// PVRTC
		if (glInternal == 0x8C00 || glInternal == 0x8C02) return ATFGPUFormat.PVRTC;
		// ETC1
		if (glInternal == 0x8D64) return ATFGPUFormat.ETC1;
		// ETC2
		if (glInternal == 0x9274 || glInternal == 0x9278) return ATFGPUFormat.ETC2;
		return null;
	}

	/**
	 * Calls uploadCallback for each mip level and face.
	 * uploadCallback(face, level, atfGPUFormat, width, height, dataLen, Bytes)
	 */
	public function readTextures(uploadCallback:UInt->Int->ATFGPUFormat->Int->Int->Int->Bytes->Void):Void
	{
		for (mipmap in mipmapData)
		{
			uploadCallback(mipmap.face, mipmap.level, cast atfGPUFormat, // ATFGPUFormat (matches OpenFL expectations)
				mipmap.width, mipmap.height,
				mipmap.size, mipmap.bytes);
		}
	}
}