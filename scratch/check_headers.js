const fs = require('fs');
const path = require('path');

const dir = 'C:\\Users\\tiend\\.gemini\\antigravity\\conversations\\';

try {
  const files = fs.readdirSync(dir).filter(f => f.endsWith('.pb'));
  console.log(`Found ${files.length} .pb files.`);
  
  for (let i = 0; i < Math.min(5, files.length); i++) {
    const filePath = path.join(dir, files[i]);
    const data = fs.readFileSync(filePath);
    console.log(`${files[i]}: size = ${data.length}, hex = ${data.slice(0, 16).toString('hex')}`);
  }
} catch (e) {
  console.error(e);
}
