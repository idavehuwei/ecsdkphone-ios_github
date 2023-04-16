module.exports = (req, res, next) => {
    if (req.method === 'POST') {
        req.method = 'GET';
    }
    // Continue to JSON Server router
    next()
};