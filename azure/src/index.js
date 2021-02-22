async function handler(context, req) {
  const param = req.query ? Object.keys(req.query)[0] : null;

	let status = 200;
	let body = "Hello World!";

	if (param === "throw") throw new Error("SERVER: Throwing error!");
	else if (param === "error") {
		console.error("SERVER: Error!");
		status = 500;
		body = "SERVER: Error!"
	} else if (param === "warn") {
		console.warn("SERVER: Warning!");
		status = 500;
		body = "SERVER: Warning!"
	}

	return {
		status,
		body,
    headers: {
      "Content-Type": "text/plain"
    }
	};
}

module.exports = { handler };