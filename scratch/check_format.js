const fs = require('fs');

const pbPath = 'C:\\Users\\tiend\\.gemini\\antigravity\\conversations\\765a92a3-760f-4672-865c-f04247a246aa.pb';

try {
  const data = fs.readFileSync(pbPath);
  console.log('Successfully read file, size:', data.length);
  
  // Print first 50 bytes in hex
  const hex = data.slice(0, 50).toString('hex');
  console.log('First 50 bytes in hex:', hex);
  
  // Let's also print it as characters
  const chars = data.slice(0, 50).toString('ascii').replace(/[^\x20-\x7E]/g, '.');
  console.log('First 50 bytes as ASCII:', chars);
  
  // Let's try to decompress it with zlib in case it is compressed
  const zlib = require('zlib');
  
  try {
    const decompressed = zlib.gunzipSync(data);
    console.log('Successfully decompressed with gzip, size:', decompressed.length);
    fs.writeFileSync('C:\\Users\\tiend\\.gemini\\antigravity\\brain\\cf34fc10-73a8-4f96-b794-41e42f8e5072\\decompressed.txt', decompressed);
  } catch (err) {
    console.log('Not gzip:', err.message);
  }
  
  try {
    const decompressed = zlib.inflateSync(data);
    console.log('Successfully decompressed with zlib inflate, size:', decompressed.length);
    fs.writeFileSync('C:\\Users\\tiend\\.gemini\\antigravity\\brain\\cf34fc10-73a8-4f96-b794-41e42f8e5072\\decompressed.txt', decompressed);
  } catch (err) {
    console.log('Not zlib inflate:', err.message);
  }

  try {
    const decompressed = zlib.unzipSync(data);
    console.log('Successfully decompressed with zlib unzip, size:', decompressed.length);
    fs.writeFileSync('C:\\Users\\tiend\\.gemini\\antigravity\\brain\\cf34fc10-73a8-4f96-b794-41e42f8e5072\\decompressed.txt', decompressed);
  } catch (err) {
    console.log('Not zlib unzip:', err.message);
  }
  
} catch (e) {
  console.error('Error:', e);
}
