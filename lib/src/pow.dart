import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_gpu/gpu.dart' as gpu;

// NOTE: We made this earlier while setting up shader bundle imports!
import '../shaders.dart';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Flutter GPU Triangle Example',
//       home: CustomPaint(
//         painter: TrianglePainter(),
//       ),
//     );
//   }
// }

class TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Attempt to access `gpu.gpuContext`.
    // If Flutter GPU isn't supported, an exception will be thrown.
    // print('Default color format: ' +
    //     gpu.gpuContext.defaultColorFormat.toString());

    final texture = gpu.gpuContext
        .createTexture(gpu.StorageMode.devicePrivate, size.width.toInt(), size.height.toInt())!;

    final renderTarget =
        gpu.RenderTarget.singleColor(gpu.ColorAttachment(texture: texture, clearValue: null));

    final image = texture.asImage();
    canvas.drawImage(image, Offset.zero, Paint());

    final commandBuffer = gpu.gpuContext.createCommandBuffer();
    final renderPass = commandBuffer.createRenderPass(renderTarget);

    final vert = shaderLibrary["PowVertex"]!;
    final frag = shaderLibrary["PowFragment"]!;
    final pipeline = gpu.gpuContext.createRenderPipeline(vert, frag);

    final vertices = Float32List.fromList([
      -0.5, -0.5, // First vertex
      0.5, -0.5, // Second vertex
      0.0, 0.5, // Third vertex
    ]);
    final verticesDeviceBuffer =
        gpu.gpuContext.createDeviceBufferWithCopy(ByteData.sublistView(vertices))!;

    renderPass.bindPipeline(pipeline);

    final verticesView = gpu.BufferView(
      verticesDeviceBuffer,
      offsetInBytes: 0,
      lengthInBytes: verticesDeviceBuffer.sizeInBytes,
    );
    renderPass.bindVertexBuffer(verticesView, 3);

    renderPass.draw();

    commandBuffer.submit();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}






// import 'dart:typed_data';
// import 'package:flutter/material.dart';
// import 'package:flutter_gpu/flutter_gpu.dart';

// class NanoWebglPow extends StatefulWidget {
//   const NanoWebglPow({super.key, required this.hashHex, required this.onWork});

//   final String hashHex;
//   final void Function(String work, int iterations) onWork;

//   @override
//   State<NanoWebglPow> createState() => _NanoWebglPowState();
// }

// class _NanoWebglPowState extends State<NanoWebglPow> {
//   late FlutterGpu _flutterGpu;
//   late GPUShaderModule _shaderModule;
//   late GPUCanvasContext _canvasContext;
//   late GPUTexture _texture;
//   late GPUBuffer _vertexBuffer;
//   late GPUBuffer _uvBuffer;
//   late GPUBuffer _work0Buffer;
//   late GPUBuffer _work1Buffer;
//   late GPUBindGroupLayout _bindGroupLayout;
//   late GPUBindGroup _bindGroup;
//   late GPURenderPipeline _renderPipeline;



//   int _width = 256 * 2;
//   int _height = 256 * 2;

//   Uint8List generateWorkBytes() {
//     final workBytes = Uint8List(8);
//     window.crypto.getRandomValues(workBytes);
//     return workBytes;
//   }



//   @override
//   void initState() {
//     super.initState();
//     _initGpu();
//   }

//   Future<void> _initGpu() async {
//     _flutterGpu = await FlutterGpu.create();
//     final adapter = await _flutterGpu.requestAdapter();
//     final device = await adapter!.requestDevice();

//     String reverseHex = String.fromCharCodes(widget.hashHex.runes.toList().reversed);  // Reverse the hash

//     final vsSource = '''
// #version 450

// layout (location = 0) in vec4 position;
// layout (location = 1) in vec2 uv;

// out vec2 uv_pos;

// void main() {
//   uv_pos = uv;
//   gl_Position = position;
// }
// ''';

//     final fsSource = '''
// #version 450

// precision highp float;
// precision highp int;

// in vec2 uv_pos;
// out vec4 fragColor;

// // Work values now supplied and read as two uint32s (uvec2)
// layout(set = 0, binding = 0) uniform uvec2 u_work_values;

// layout(set = 0, binding = 1) uniform uvec4 u_hash_part1;
// layout(set = 0, binding = 2) uniform uvec4 u_hash_part2;

// // ... (Rest of the shader code, Blake2B implementation)
// // Remember to replace the old uniform declarations and logic with new ones.


// #define BLAKE2B_IV32_1 0x6A09E667u
// uint v[32] = uint[32](
//       0xF2BDC900u, 0x6A09E667u, 0x84CAA73Bu, 0xBB67AE85u,
//       0xFE94F82Bu, 0x3C6EF372u, 0x5F1D36F1u, 0xA54FF53Au,
//       0xADE682D1u, 0x510E527Fu, 0x2B3E6C1Fu, 0x9B05688Cu,
//       0xFB41BD6Bu, 0x1F83D9ABu, 0x137E2179u, 0x5BE0CD19u,
//       0xF3BCC908u, 0x6A09E667u, 0x84CAA73Bu, 0xBB67AE85u,
//       0xFE94F82Bu, 0x3C6EF372u, 0x5F1D36F1u, 0xA54FF53Au,
//       0xADE682F9u, 0x510E527Fu, 0x2B3E6C1Fu, 0x9B05688Cu,
//       0x04BE4294u, 0xE07C2654u, 0x137E2179u, 0x5BE0CD19u
// );
// // Input data buffer
//     uint m[32]; //Rest of Blake2B code same as before

//     void main() {
//       int i;
//       uint uv_x = uint(uv_pos.x * ${_width - 1}.);
//       uint uv_y = uint(uv_pos.y * ${_height - 1}.);
//       uint x_pos = uv_x % 256u;
//       uint y_pos = uv_y % 256u;
//       uint x_index = (uv_x - x_pos) / 256u;
//       uint y_index = (uv_y - y_pos) / 256u;

//       // Assemble work value based on new uniforms
//         m[0] = (x_pos ^ (y_pos << 8) ^ ((u_work_values.y ^ x_index) << 16) ^ ((u_work_values.x ^ y_index) << 24));


// // Block hash parts
// m[2] = u_hash_part1.x;
// m[3] = u_hash_part1.y;
// m[4] = u_hash_part1.z;
// m[5] = u_hash_part1.w;
// m[6] = u_hash_part2.x;
// m[7] = u_hash_part2.y;
// m[8] = u_hash_part2.z;
// m[9] = u_hash_part2.w;
//    // ... Rest of the Blake2B and threshold check logic (same)
//   if((BLAKE2B_IV32_1 ^ v[1] ^ v[17]) > 0xFFFFFFF8u) { // Example threshold
//         fragColor = vec4(
//           float(x_index + 1u)/255., 
//           float(y_index + 1u)/255., 
//           float(x_pos)/255., 
//           float(y_pos)/255.  
//         );
//       }
//     }

// ''';



//     _shaderModule = device!.createShaderModule(
//         code: _flutterGpu.glslToSpirv(vsSource, type: 'vert') +
//             _flutterGpu.glslToSpirv(fsSource, type: 'frag')); // Add corresponding spirv code for shaders

//  // ... (rest of the setup code, vertex buffers, textures etc.)
//     _canvasContext = device.createCanvasContext(width: _width, height: _height);
//     _texture = _canvasContext.createTexture(
//         format: GPUTextureFormat.rgba8unorm,
//         usage: GPUTextureUsage.renderAttachment | GPUTextureUsage.copySrc,
//         width: _width,
//         height: _height,
//     );

// // rest of dart code such as buffers, pipeline setup




//   }


//   @override
//   Widget build(BuildContext context) {
//     return Container(); // Or a widget to display the canvas/results
//   }
// }