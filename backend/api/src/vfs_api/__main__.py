"""
Main FastAPI application entry point.
This module initializes the FastAPI application and includes all routes.
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import argparse
import logging
import uvicorn

# Import service routers
from vfs_api.routes import router as api_router

def create_app(args):
    app = FastAPI(
        title="VFS API",
        description="Virtual File System API for managing directories and files",
        version="1.0.0"
    )

    # Add CORS middleware for HTTP endpoints
    app.add_middleware(
        CORSMiddleware,
        allow_origins=args.cors_origins.split(","),
        allow_credentials=args.cors_allow_credentials,
        allow_methods=args.cors_allow_methods.split(","),
        allow_headers=args.cors_allow_headers.split(","),
        max_age=args.cors_max_age,
        expose_headers=["*"],
    )

    # Include service routers
    app.include_router(api_router)

    @app.get("/health")
    async def health_check():
        return {"status": "ok"}

    return app


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", type=str, default="0.0.0.0")
    parser.add_argument("--port", type=int, default=5678)
    parser.add_argument("--verbose", action='store_true', help="Verbose logging")

    # Update default CORS settings
    parser.add_argument("--cors_origins", type=str,
                       default="*",
                       help="Comma-separated list of allowed CORS origins")
    parser.add_argument("--cors_allow_credentials",
                       action="store_true", default=True,
                       help="Allow credentials in CORS requests")
    parser.add_argument("--cors_allow_methods", type=str,
                       default="GET,POST,PUT,DELETE,OPTIONS,PATCH,HEAD,CONNECT",
                       help="Comma-separated list of allowed HTTP methods")
    parser.add_argument("--cors_allow_headers", type=str,
                       default="Content-Type,Authorization,Accept,Origin,Connection,Upgrade,Sec-WebSocket-Key,Sec-WebSocket-Version,Sec-WebSocket-Extensions,Sec-WebSocket-Protocol,X-ClientId,X-SocketId",
                       help="Comma-separated list of allowed HTTP headers")
    parser.add_argument("--cors_max_age", type=int, default=600,
                        help="Maximum time (in seconds) to cache CORS preflight responses")

    args = parser.parse_args()

    # Move logging configuration here and set it based on verbose flag
    log_level = logging.DEBUG if args.verbose else logging.ERROR
    logging.basicConfig(level=log_level)

    # Create FastAPI app
    app = create_app(args)


    app_log_level = "debug" if args.verbose else "error"

    uvicorn.run(app, host=args.host, port=args.port, log_level=app_log_level)

if __name__ == '__main__':
    main()