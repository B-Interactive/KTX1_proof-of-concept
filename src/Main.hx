package;

import openfl.Assets;
import openfl.Vector;
import openfl.display.Sprite as OpenFLSprite;
import openfl.events.Event as OpenFLEvent;
import starling.core.Starling;
import starling.display.MovieClip;
import starling.display.Sprite;
import starling.events.Event;
import starling.text.BitmapFont;
import starling.text.TextField;
import starling.text.TextFieldAutoSize;
import starling.textures.Texture;
import starling.textures.TextureAtlas;
import starling.utils.AssetManager;
import starling.utils.Color;
#if sys
import sys.FileSystem;
#end

class Main extends OpenFLSprite {
	public var starling:Starling;

	public function new() {
		super();

		addEventListener(OpenFLEvent.ADDED_TO_STAGE, init);
	}

	private function init(e:OpenFLEvent = null):Void {
		removeEventListener(OpenFLEvent.ADDED_TO_STAGE, init);

		// Minimal Starling setup
		starling = new Starling(StarlingRoot, stage);
		starling.start();

		// Listen for OpenFL resize events
		stage.addEventListener(OpenFLEvent.RESIZE, onResize);
	}

	private function onResize(e:OpenFLEvent):Void {
		// Update Starling viewport and stage size
		if (starling != null) {
			starling.viewPort.width = stage.stageWidth;
			starling.viewPort.height = stage.stageHeight;
			starling.stage.stageWidth = stage.stageWidth;
			starling.stage.stageHeight = stage.stageHeight;			
			var starlingRoot:StarlingRoot = cast (starling.root, StarlingRoot);
			if (starlingRoot != null)
				starlingRoot.layoutGrid();
			// Optionally, force Starling to redraw
			starling.nextFrame();
		}
	}
}

// The Starling display root
class StarlingRoot extends Sprite {
	private var assetManager:AssetManager;
	private var anims:Array<Sprite>;

	public function new() {
		super();
		addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
	}

	private function onAddedToStage(e:Event = null):Void {
		#if sys
		loadAssets("assets/img/", ".png");
		loadAssets("assets/atf/", ".atf");
		loadAssets("assets/ktx/", ".ktx");
		#elseif html5
		loadAssets();
		#end

		var src:Vector<String> = assetManager.getTextureNames();
		var seen = new Map<String, Bool>();
		var animations = [];
		// Get unique animation names
		for (s in src) {
			var base = s.split(".")[0];
			if (!seen.exists(base)) {
				seen.set(base, true);
				animations.push(base);
			}
		}

		anims = new Array<Sprite>();
		for (i in 0...animations.length) {
			var sprite:Sprite = new Sprite();
			addChild(sprite);

			var movieClip:MovieClip = new MovieClip(assetManager.getTextures(animations[i]));
			// movieClip.scale = 0.7;
			sprite.addChild(movieClip);
			Starling.current.juggler.add(movieClip);

			// Text with format/codec details
			var text:TextField = new TextField(Std.int(movieClip.width), BitmapFont.NATIVE_SIZE * 2, animations[i]);
			text.format.setTo(BitmapFont.MINI, BitmapFont.NATIVE_SIZE * 3, Color.WHITE);
			text.autoSize = TextFieldAutoSize.BOTH_DIRECTIONS;
			text.x = (movieClip.width * 0.5) - (text.width * 0.5);
			text.y = movieClip.height - (text.height * 2);
			sprite.addChild(text);

			anims.push(sprite);
		}

		// Arrange anims
		layoutGrid();
	}

	public function layoutGrid(e:Event = null):Void {
		if (anims == null || anims.length == 0) return;

        // Calculate cell size (use first anim as basis, or find max dimensions)
        var cellWidth = 0;
        var cellHeight = 0;
        for (sprite in anims) {
            cellWidth = Std.int(Math.max(cellWidth, sprite.width));
            cellHeight = Std.int(Math.max(cellHeight, sprite.height));
        }
        if (cellWidth == 0 || cellHeight == 0) return;

        var xnum = Math.floor(stage.stageWidth / cellWidth);
        if (xnum <= 0) xnum = 1; // Avoid div by zero

        for (i in 0...anims.length) {
            var col = i % xnum;
            var row = Math.floor(i / xnum);
            var sprite = anims[i];
            sprite.x = cellWidth * col;
            sprite.y = cellHeight * row;
        }
	}

	#if sys
	private function loadAssets(path:String, textureExtension:String):Void {
		if (assetManager == null) {
			assetManager = new AssetManager();
		}

		var textureFiles = FileSystem.readDirectory(path).filter(function(f) return StringTools.endsWith(f, textureExtension));
		var xmlFiles = FileSystem.readDirectory(path).filter(function(f) return StringTools.endsWith(f, ".xml"));

		// Build a map of xml files for quick lookup
		var xmlMap = new Map<String, String>();
		for (xml in xmlFiles) {
			var base = xml.substr(0, xml.length - 4); // remove extension
			xmlMap.set(base, xml);
		}

		// Match and process
		for (tex in textureFiles) {
			var base = tex.substr(0, tex.length - 4); // remove extension
			if (xmlMap.exists(base)) {
				var texPath = path + tex;
				var xmlPath = path + xmlMap.get(base);
				trace(texPath);
				trace(xmlPath);
				if (textureExtension != ".png") {
					assetManager.addTextureAtlas(texPath, new TextureAtlas(Texture.fromData(Assets.getBytes(texPath)), Xml.parse(Assets.getText(xmlPath))));
				} else {
					assetManager.addTextureAtlas(texPath,
						new TextureAtlas(Texture.fromBitmapData(Assets.getBitmapData(texPath)), Xml.parse(Assets.getText(xmlPath))));
				}
			}
		}
	}
	#elseif html5
	private function loadAssets():Void {
		if (assetManager == null) {
			assetManager = new AssetManager();
		}

		var textureFiles:Array<Array<String>> = [
			["assets/atf/cat_run_atf-dxt1.atf", "assets/atf/cat_run_atf-dxt1.xml"],
			["assets/atf/cat_run_atf-dxt5.atf", "assets/atf/cat_run_atf-dxt5.xml"],
			["assets/atf/cat_run_atf-etc1.atf", "assets/atf/cat_run_atf-etc1.xml"],
			["assets/atf/cat_run_atf-etc2.atf", "assets/atf/cat_run_atf-etc2.xml"],
			["assets/atf/cat_run_atf-pvrtc.atf", "assets/atf/cat_run_atf-pvrtc.xml"],
			["assets/ktx/cat_run_ktx-dxt1.ktx", "assets/ktx/cat_run_ktx-dxt1.xml"],
			["assets/ktx/cat_run_ktx-dxt5.ktx", "assets/ktx/cat_run_ktx-dxt5.xml"],
			["assets/ktx/cat_run_ktx-etc1.ktx", "assets/ktx/cat_run_ktx-etc1.xml"],
			[
				"assets/ktx/cat_run_ktx-etc2-rgb-noalpha.ktx",
				"assets/ktx/cat_run_ktx-etc2-rgb-noalpha.xml"
			],
			["assets/ktx/cat_run_ktx-etc2-rgba.ktx", "assets/ktx/cat_run_ktx-etc2-rgba.xml"],
			[
				"assets/ktx/cat_run_ktx-pvrtci-4bpp-rgba.ktx",
				"assets/ktx/cat_run_ktx-pvrtci-4bpp-rgba.xml"
			]
		];

		// First, the PNG reference
		assetManager.addTextureAtlas("assets/img/cat_run_png.png",
			new TextureAtlas(Texture.fromBitmapData(Assets.getBitmapData("assets/img/cat_run_png.png")),
				Xml.parse(Assets.getText("assets/img/cat_run_png.xml"))));
		// Now the rest
		for (tex in textureFiles) {
			assetManager.addTextureAtlas(tex[0], new TextureAtlas(Texture.fromData(Assets.getBytes(tex[0])), Xml.parse(Assets.getText(tex[1]))));
		}
	}
	#end
}
