const { openBrowser, goto, below, click, closeBrowser } = require('taiko');
(async () => {
    try {
        await openBrowser();
        let url=process.env.SERVICE_TRACKER_URL
        await goto(url);
        for (let iter = 0; iter < 10; iter++) {
            await click("REFRESH DATA", below("Quakes"));
            await click("REFRESH DATA", below("Weather"));
            await click("REFRESH DATA", below("Flights"));
            await click("Flights");
            await click("Earthquakes");
            await click("Weather");
            await click("Profile");
            await click("Dashboard");
        }
    } catch (error) {
        console.error(error);
    } finally {
        await closeBrowser();
    }
})();
