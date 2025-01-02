const errorHandler = (err, req, res, next) => {
    console.error(err.stack);

    // Prisma error handling
    if (err.code && err.code.startsWith('P')) {
        return res.status(400).json({
            success: false,
            message: 'Database error',
            error: process.env.NODE_ENV === 'development' ? err.message : 'An error occurred'
        });
    }

    // Default error
    res.status(err.status || 500).json({
        success: false,
        message: err.message || 'Internal server error',
        error: process.env.NODE_ENV === 'development' ? err.stack : undefined
    });
};

module.exports = errorHandler;
