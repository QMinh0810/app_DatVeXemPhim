const fs = require('fs');

const pbPath = 'C:\\Users\\tiend\\.gemini\\antigravity\\conversations\\765a92a3-760f-4672-865c-f04247a246aa.pb';

try {
  const data = fs.readFileSync(pbPath);
  console.log('Successfully read file, size:', data.length);
  
  // Convert buffer to binary string to preserve every byte 1:1
  const rawStr = data.toString('binary');
  
  // Helper to find all occurrences of a term and print surrounding text
  function findOccurrences(term, contextLength = 2000) {
    let index = 0;
    let count = 0;
    console.log(`\n=== Searching for "${term}" ===`);
    
    while (true) {
      index = rawStr.indexOf(term, index);
      if (index === -1) break;
      
      count++;
      console.log(`\nOccurrence ${count} at index ${index}:`);
      
      // Get context around the occurrence
      const start = Math.max(0, index - 200);
      const end = Math.min(rawStr.length, index + contextLength);
      const context = rawStr.substring(start, end);
      
      // Clean up non-printable binary bytes to make it readable in console
      const readableContext = context.replace(/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F-\xFF]/g, (char) => {
        // If it's a Vietnamese character in UTF-8, it will be multi-byte. 
        // In binary string, they are represented as separate characters. 
        // Let's keep characters >= 0x80 for now, but decode them properly or print them.
        return char;
      });
      
      // Try to convert the binary substring back to proper UTF-8 buffer and string
      const buf = Buffer.from(context, 'binary');
      const utf8Str = buf.toString('utf-8');
      
      console.log('--- DECODED UTF-8 ---');
      console.log(utf8Str);
      console.log('---------------------');
      
      // Write the decoded context to a file
      fs.writeFileSync(`C:\\Users\\tiend\\.gemini\\antigravity\\brain\\cf34fc10-73a8-4f96-b794-41e42f8e5072\\report_context_${count}.txt`, utf8Str, 'utf-8');
      
      index += term.length;
    }
    console.log(`Found ${count} occurrences of "${term}".`);
  }
  
  findOccurrences('Flutter');
  findOccurrences('GIỚI THIỆU');

} catch (e) {
  console.error('Error:', e);
}
