const handler = async (event, context, callback) => {
	const param = event.queryStringParameters ? Object.keys(event.queryStringParameters)[0] : null;

	let statusCode = 200;
	let body = "Hello World!";

	if (param === "throw") throw new Error("SERVER: Throwing error!");
	else if (param === "error") {
		console.error("SERVER: Error!");
		statusCode = 500;
		body = "SERVER: Error!"
	} else if (param === "warn") {
		console.warn("SERVER: Warning!");
		statusCode = 500;
		body = "SERVER: Warning!"
	}

	const response = {
		statusCode,
		body,
    headers: {
      "Content-Type": "text/plain"
    }
	};

	callback(null, response);
};

module.exports = { handler };