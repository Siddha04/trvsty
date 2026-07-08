import 'dart:io';
import 'dart:typed_data';

/// VM/IO implementation of Gzip decompression using dart:io.
Uint8List decompressGzip(Uint8List bytes) {
  return Uint8List.fromList(gzip.decode(bytes));
}
