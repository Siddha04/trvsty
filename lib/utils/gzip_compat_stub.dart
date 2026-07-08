import 'dart:typed_data';

/// Stub implementation of Gzip decompression for platforms that do not support dart:io.
Uint8List decompressGzip(Uint8List bytes) {
  throw UnsupportedError('Gzip decompression is not supported on this platform.');
}
