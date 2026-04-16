const puppeteer = require('puppeteer');

(async () => {
    try {
        console.log("Waiting for vote service to come online...");
        await new Promise(r => setTimeout(r, 5000));

        console.log("Submitting test vote...");
        await fetch("http://vote", {
            method: "POST",
            body: new URLSearchParams({ "vote": "b" }),
            headers: { "Content-Type": "application/x-www-form-urlencoded" }
        });

        console.log("Waiting for backend workers to process vote (10s)...");
        await new Promise(r => setTimeout(r, 10000));

        console.log("Launching headless browser to evaluate Result UI...");
        const browser = await puppeteer.launch({ 
            args: ['--no-sandbox', '--disable-setuid-sandbox'] 
        });
        const page = await browser.newPage();
        
        await page.goto('http://result');
        
        // Wait dynamically for Angular/Socket.io to update the DOM
        await page.waitForFunction('document.body.innerText.includes("1 vote")', { timeout: 10000 });
        
        await browser.close();
        
        console.log("\x1b[42m\x1b[30m------------\x1b[0m");
        console.log("\x1b[42m\x1b[30mTests passed\x1b[0m");
        console.log("\x1b[42m\x1b[30m------------\x1b[0m");
        process.exit(0);
        
    } catch (err) {
        console.error("\x1b[41m\x1b[37m------------\x1b[0m");
        console.error("\x1b[41m\x1b[37mTests failed\x1b[0m");
        console.error(err);
        console.error("\x1b[41m\x1b[37m------------\x1b[0m");
        process.exit(1);
    }
})();
