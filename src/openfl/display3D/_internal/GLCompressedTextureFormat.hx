package openfl.display3D._internal;

/**
 * Centralized GL compressed texture format constants.
 * See: https://github.khronos.org/KTX-Software/pyktx/_modules/pyktx/gl_internalformat.html *
 */
#if (haxe_ver >= 4.0) enum #else @:enum #end abstract GLCompressedTextureFormat(Int) {
    // S3TC/DXT
    public var COMPRESSED_RGB_S3TC_DXT1_EXT = 0x83F0; // DXT1
    public var COMPRESSED_RGBA_S3TC_DXT1_EXT = 0x83F1; // DXT1 w/ 1-bit alpha
    public var COMPRESSED_RGBA_S3TC_DXT5_EXT = 0x83F3; // DXT5

    // ETC1/2
    public var ETC1_RGB8_OES = 0x8D64;
    public var COMPRESSED_RGB8_ETC2 = 0x9274;
    public var COMPRESSED_RGBA8_ETC2_EAC = 0x9278;

    // PVRTC
    public var COMPRESSED_RGB_PVRTC_4BPPV1_IMG = 0x8C00;    
    public var COMPRESSED_RGBA_PVRTC_4BPPV1_IMG = 0x8C02;

    /**
     * Human-readable string for GL compressed format.
     */
    public static function toString(fmt:GLCompressedTextureFormat):String {
        return switch (fmt) {
            case COMPRESSED_RGB_S3TC_DXT1_EXT: "DXT1";
            case COMPRESSED_RGBA_S3TC_DXT1_EXT: "DXT1A";
            case COMPRESSED_RGBA_S3TC_DXT5_EXT: "DXT5";
            case ETC1_RGB8_OES: "ETC1";
            case COMPRESSED_RGB8_ETC2: "ETC2_RGB";
            case COMPRESSED_RGBA8_ETC2_EAC: "ETC2_RGBA";
            case COMPRESSED_RGB_PVRTC_4BPPV1_IMG: "PVRTC4_RGB";
            case COMPRESSED_RGBA_PVRTC_4BPPV1_IMG: "PVRTC4_RGBA";
            default: "UNKNOWN";
        }
    }

    /**
     * Returns block size in bytes for given format.
     * For PVRTC4, this is not per-block, but total image size = width*height/2.
     */
    public static function blockBytes(fmt:GLCompressedTextureFormat):Int {
        return switch (fmt) {
            case COMPRESSED_RGB_S3TC_DXT1_EXT,
                 COMPRESSED_RGBA_S3TC_DXT1_EXT,
                 ETC1_RGB8_OES,
                 COMPRESSED_RGB8_ETC2:
                8;
            case COMPRESSED_RGBA_S3TC_DXT5_EXT,
                 COMPRESSED_RGBA8_ETC2_EAC:
                16;
            // PVRTC4: block size is not used, use image size calculation instead
            case COMPRESSED_RGB_PVRTC_4BPPV1_IMG,
                 COMPRESSED_RGBA_PVRTC_4BPPV1_IMG:
                0; // handled specially
            default: 0;
        }
    }

    /**
     * (Not yet implemented)
     * Returns true if format is sRGB.
     */
    /* public static function isSRGB(fmt:GLCompressedTextureFormat):Bool {
        return switch (fmt) {
            case COMPRESSED_SRGB_S3TC_DXT1_EXT,
                 COMPRESSED_SRGB_ALPHA_S3TC_DXT1_EXT,
                 COMPRESSED_SRGB_ALPHA_S3TC_DXT5_EXT:
                true;
            default: false;
        }
    } */

    /**
     * Returns true if format supports alpha.
     */
    public static function hasAlpha(fmt:GLCompressedTextureFormat):Bool {
        return switch (fmt) {
            case COMPRESSED_RGBA_S3TC_DXT1_EXT,
                 COMPRESSED_RGBA_S3TC_DXT5_EXT,
                 COMPRESSED_RGBA8_ETC2_EAC,
                 COMPRESSED_RGBA_PVRTC_4BPPV1_IMG:
                true;
            default: false;
        }
    }
}