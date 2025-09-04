# KTX1 Proof-of-Concept for OpenFL & Starling

This repository demonstrates a **proof-of-concept for KTX1 container support for textures** in [OpenFL](https://openfl.org/) and [Starling](https://gamua.com/starling/).
It is designed to help evaluate how the open-spec KTX1 texture container could be integrated into the OpenFL ecosystem to provide an alternative to the closed-spec ATF container, for accelerated, compressed GPU textures across platforms.

---

## What Is KTX1?

KTX1 is a widely used container format for compressed GPU textures, designed by the Khronos Group.  
This proof of concept implements KTX1 handling for OpenFL and Starling, currently leveraging only existing ATF-compatible texture compression formats (i.e., only formats already supported by OpenFL and Starling’s ATF pipeline).

---

## Running the Project

You can run this project on any OpenFL-supported target.  
**Typical usage:**  

First, install [Haxe](https://haxe.org/).

```bash
# Install dependencies if needed
haxelib install openfl
haxelib run openfl setup
haxelib install starling
```

```bash
# Clone this repository
git clone https://github.com/B-Interactive/KTX1_proof-of-concept.git
cd KTX1_proof-of-concept

# Run for HTML5
openfl test html5

# Run for desktop (Linux, macOS, Windows)
openfl test neko
openfl test cpp

# Run for Flash/AIR (untested)
openfl test flash
openfl test air
```

---

## What to Expect (Output & Platform Limitations)

- On launch, you should see a selection of simple cat animations.
- Each animation represents a different container + texture compression format.
- The three container types are ATF (classic), XTC1 (new) and PNG (reference).
- The texture compression formats are DXT1/5, ETC1,2 and PVRTC.
- **Not all cat animations will be visible**  
  This is expected: most platforms do **not** support all GL extensions or compressed formats simultaneously.
- The demo will only show animations for formats supported by your system’s GL extensions.  
  You may see blank frames, missing cats, reduced quality or skipped animations for unsupported formats.

---

## Current Limitations

- **Texture Compression Format Support:**  
  This proof-of-concept only supports the same texture compression formats already enabled for ATF in OpenFL/Starling.
    - If your platform/GPU does **not** support any of these formats, the corresponding KTX1 textures will not display.
    - No new texture compression formats or decompression routines have been added... yet.

---