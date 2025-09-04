package starling.textures;

import openfl.display3D._internal.GLCompressedTextureFormat;
import openfl.display3D._internal.KTX1Reader;
import openfl.utils.ByteArray;

/** Parses the KTX1 data format */
class Ktx1Data {
	private var _format:String;
	private var _width:Int;
	private var _height:Int;
	private var _numTextures:Int;
	private var _isCubeMap:Bool;
	private var _data:ByteArray;
	private var _hasAlpha:Bool;

	public function new(data:ByteArray) {
		var reader = new KTX1Reader(data, 0);
		_width = reader.width;
		_height = reader.height;
		_numTextures = reader.mipCount;
		_isCubeMap = false; // Proof of concept: only 2D supported

		// Determine Starling/OpenFL texture format based on KTX format
		var ktxFormat = reader.glInternalFormat;
		_hasAlpha = GLCompressedTextureFormat.hasAlpha(ktxFormat);
		_data = data;
	}

	/** The texture format. @see openfl.display3D.Context3DTextureFormat */
	public var format(get, never):String;

	private function get_format():String {
		return _format;
	}

	/** The width of the texture in pixels. */
	public var width(get, never):Int;

	private function get_width():Int {
		return _width;
	}

	/** The height of the texture in pixels. */
	public var height(get, never):Int;

	private function get_height():Int {
		return _height;
	}

	/** The number of encoded textures. '1' means that there are no mip maps. */
	public var numTextures(get, never):Int;

	private function get_numTextures():Int {
		return _numTextures;
	}

	/** Indicates if the KTX1 data encodes a cube map. Not supported in proof of concept */
	public var isCubeMap(get, never):Bool;

	private function get_isCubeMap():Bool {
		return _isCubeMap;
	}

	/** The actual byte data, including header. */
	public var data(get, never):ByteArray;

	private function get_data():ByteArray {
		return _data;
	}

	/** Indicates if the texture format has alpha support. */
	public var hasAlpha(get, never):Bool;

	private function get_hasAlpha():Bool {
		return _hasAlpha;
	}
}
