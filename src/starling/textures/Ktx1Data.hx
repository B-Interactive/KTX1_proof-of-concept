package starling.textures;

import openfl.display3D._internal.KTX1Reader;
import openfl.utils.ByteArray;

/** Parses the KTX1 data format */
class Ktx1Data {
	private var _width:Int;
	private var _height:Int;
	private var _numTextures:Int;
	private var _faceCount:Int;
	private var _format:String;
	private var _glInternalFormat:Int;
	private var _glBaseInternalFormat:Int;
	private var _atfGPUFormat:Dynamic; // ATFGPUFormat
	private var _data:ByteArray;
	private var _hasAlpha:Bool;

	public function new(data:ByteArray) {
		var reader = new KTX1Reader(data, 0);
		_width = reader.width;
		_height = reader.height;
		_numTextures = reader.mipCount;
		_faceCount = 1; // Only 2D supported for now
		_format = reader.format;
		_glInternalFormat = reader.glInternalFormat;
		_glBaseInternalFormat = reader.glBaseInternalFormat;
		_atfGPUFormat = reader.atfGPUFormat;
		_data = data;
		_hasAlpha = reader.hasAlpha;
	}

	public var format(get, never):String;
	private function get_format():String { return _format; }

	public var width(get, never):Int;
	private function get_width():Int { return _width; }

	public var height(get, never):Int;
	private function get_height():Int { return _height; }

	public var numTextures(get, never):Int;
	private function get_numTextures():Int { return _numTextures; }

	public var faceCount(get, never):Int;
	private function get_faceCount():Int { return _faceCount; }

	public var glInternalFormat(get, never):Int;
	private function get_glInternalFormat():Int { return _glInternalFormat; }

	public var glBaseInternalFormat(get, never):Int;
	private function get_glBaseInternalFormat():Int { return _glBaseInternalFormat; }

	public var atfGPUFormat(get, never):Dynamic;
	private function get_atfGPUFormat():Dynamic { return _atfGPUFormat; }

	public var data(get, never):ByteArray;
	private function get_data():ByteArray { return _data; }

	public var hasAlpha(get, never):Bool;
	private function get_hasAlpha():Bool { return _hasAlpha; }
}