const fs = require('fs');
const path = require('path');

const dir = 'C:\\Users\\tiend\\.gemini\\antigravity\\conversations\\';

try {
  const files = fs.readdirSync(dir).filter(f => f.endsWith('.pb'));
  console.log(`Searching in ${files.length} .pb files...`);
  
  for (const file of files) {
    const filePath = path.join(dir, file);
    const data = fs.readFileSync(filePath);
    
    // Check if "Flutter" or "neondb" exists in raw ascii
    const str = data.toString('utf8');
    if (str.includes('Flutter') || str.includes('neondb') || str.includes('Express.js') || str.includes('vnpay')) {
      console.log(`FOUND KEYWORD IN ${file}: size = ${data.length}`);
      
      // Print context
      const index = str.indexOf('Flutter');
      if (index !== -1) {
        console.log(str.substring(index - 100, index + 500));
      }
    }
  }
} catch (e) {
  console.error(e);
}
