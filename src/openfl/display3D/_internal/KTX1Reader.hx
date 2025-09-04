package openfl.display3D._internal;

import haxe.io.Bytes;
import openfl.display3D._internal.GLCompressedTextureFormat;
import openfl.errors.IllegalOperationError;
import openfl.utils.ByteArray;

/**
 * Supports common compressed formats: DXT1/5, ETC1/2, PVRTC4.
 */
class KTX1Reader {
	public var width:Int;
	public var height:Int;
	public var mipCount:Int;
	public var format:String;
	public var glInternalFormat:GLCompressedTextureFormat;
	public var glBaseInternalFormat:Int;

	private var mipmapData:Array<{
		level:Int,
		width:Int,
		height:Int,
		size:Int,
		bytes:Bytes
	}>;

	public function new(data:ByteArray, byteArrayOffset:UInt = 0) {
		data.position = byteArrayOffset;

		// Check KTX1 magic number
		var magic = [0xAB, 0x4B, 0x54, 0x58, 0x20, 0x31, 0x31, 0xBB, 0x0D, 0x0A, 0x1A, 0x0A];
		for (i in 0...magic.length) {
			if (data[byteArrayOffset + i] != magic[i])
				throw new IllegalOperationError("KTX1 signature not found");
		}

		data.endian = openfl.utils.Endian.LITTLE_ENDIAN;

		// Parse header fields
		data.position = byteArrayOffset + 12;
		var endianness = data.readUnsignedInt();
		if (endianness != 0x04030201)
			throw new IllegalOperationError("KTX1: Unexpected endianness");

		var glType = data.readUnsignedInt();
		var glTypeSize = data.readUnsignedInt();
		var glFormat = data.readUnsignedInt();
		glInternalFormat = cast(data.readUnsignedInt(), GLCompressedTextureFormat);
		glBaseInternalFormat = data.readUnsignedInt();
		width = data.readUnsignedInt();
		height = data.readUnsignedInt();
		var depth = data.readUnsignedInt();
		var arrayElements = data.readUnsignedInt();
		var faces = data.readUnsignedInt();
		mipCount = data.readUnsignedInt();
		var keyValueDataBytes = data.readUnsignedInt();

		if (depth > 0 || arrayElements > 0 || faces > 1)
			throw new IllegalOperationError("KTX1 only supports 2D, non-array, non-cubemap textures");

		data.position += keyValueDataBytes;

		// Supported formats (reference GLCompressedTextureFormat)
		var supportedFormats = [
			GLCompressedTextureFormat.COMPRESSED_RGB_S3TC_DXT1_EXT,
			GLCompressedTextureFormat.COMPRESSED_RGBA_S3TC_DXT1_EXT,
			GLCompressedTextureFormat.COMPRESSED_RGBA_S3TC_DXT5_EXT,
			GLCompressedTextureFormat.ETC1_RGB8_OES,
			GLCompressedTextureFormat.COMPRESSED_RGB8_ETC2,
			GLCompressedTextureFormat.COMPRESSED_RGBA8_ETC2_EAC,
			GLCompressedTextureFormat.COMPRESSED_RGB_PVRTC_4BPPV1_IMG,
			GLCompressedTextureFormat.COMPRESSED_RGBA_PVRTC_4BPPV1_IMG
		];

		if (supportedFormats.indexOf(glInternalFormat) == -1) {
			throw new IllegalOperationError("KTX1 support currently only includes DXT1/DXT5/ETC1/ETC2/PVRTC4 codecs (got: 0x"
				+ StringTools.hex(cast(glInternalFormat, Int), 4)
				+ ")");
		}

		format = GLCompressedTextureFormat.toString(glInternalFormat);

		// Parse all mipmap levels
		mipmapData = [];
		var levelWidth = width;
		var levelHeight = height;
		for (level in 0...mipCount) {
			// Each mip level starts with imageSize, then image data, then 4-byte alignment
			if (data.position + 4 > data.length)
				throw new IllegalOperationError('KTX1: Unexpected EOF reading mipmap imageSize');
			var imageSize = data.readUnsignedInt();

			if (data.position + imageSize > data.length)
				throw new IllegalOperationError('KTX1: Unexpected EOF reading mipmap imageData');

			var imageBytes = Bytes.alloc(imageSize);
			data.readBytes(imageBytes, 0, imageSize);

			mipmapData.push({
				level: level,
				width: levelWidth,
				height: levelHeight,
				size: imageSize,
				bytes: imageBytes
			});

			// Advance to next 4-byte boundary (padding, per KTX spec)
			var pad = (4 - (imageSize % 4)) % 4;
			data.position += pad;

			// Next level dimensions (minimum 1)
			levelWidth = Std.int(Math.max(1, levelWidth >> 1));
			levelHeight = Std.int(Math.max(1, levelHeight >> 1));
		}
	}

	/**
	 * Calls uploadCallback for each mip level.
	 * uploadCallback(target, level, gpuFormat, width, height, dataLen, Bytes)
	 */
	public function readTextures(uploadCallback:UInt->Int->Int->Int->Int->Int->Bytes->Void):Void {
		for (mipmap in mipmapData) {
			uploadCallback(0, // target (no cubemap)
				mipmap.level, cast(glInternalFormat, Int), // gpuFormat
				mipmap.width, mipmap.height, mipmap.size,
				mipmap.bytes);
		}
	}
}
