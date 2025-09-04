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
	public var data:ByteArray;
	public var format:String;
	public var glInternalFormat:GLCompressedTextureFormat;
	public var glBaseInternalFormat:Int;

	public function new(data:ByteArray, byteArrayOffset:UInt = 0) {
		this.data = data;
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

		// Read image data for mip 0 (Proof of concept: only first mip)
		var imageSize = data.readUnsignedInt();
		var imageDataOffset = data.position;
		var imageDataLength = imageSize;

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

		// Use GLCompressedTextureFormat helper for format string
		format = GLCompressedTextureFormat.toString(glInternalFormat);

		// Extract mipmap bytes
		var mipmapBytes = new ByteArray();
		data.readBytes(mipmapBytes, 0, imageDataLength);
		this.data = mipmapBytes;
	}

	/**
	 * Only calls callback for single mip level.
	 */
	public function readTextures(uploadCallback:UInt->Int->Int->Int->Int->Int->Bytes->Void):Void {
		// Use helper for block size
		var blockBytes = GLCompressedTextureFormat.blockBytes(glInternalFormat);

		// Special case for PVRTC4: total image size = ceil(width * height / 2)
		var expectedBlockSize = switch (glInternalFormat) {
			case GLCompressedTextureFormat.COMPRESSED_RGB_PVRTC_4BPPV1_IMG, GLCompressedTextureFormat.COMPRESSED_RGBA_PVRTC_4BPPV1_IMG:
				Math.ceil(width * height / 2);
			default:
				((width + 3) >> 2) * ((height + 3) >> 2) * blockBytes;
		};

		if (data.length != expectedBlockSize) {
			trace("ERROR: KTX1 " + format + " data length mismatch: got " + data.length + ", expected " + expectedBlockSize);
			// Optionally: fallback or throw
		}

		#if (js || html5)
		// Check for S3TC extension (WebGL)
		var canvas:js.html.CanvasElement = js.Browser.document.createCanvasElement();
		var gl = canvas.getContext('webgl');
		var ext = gl.getExtension('WEBGL_compressed_texture_s3tc');
		if (ext == null) {
			trace("ERROR: S3TC/DXT5 not supported in this browser!");
			// Optionally fallback
		}
		#end

		uploadCallback(0, // target (no cubemap)
			0, // level
			cast(glInternalFormat, Int), // gpuFormat
			width, height, data.length, Bytes.ofData(data));
	}
}
