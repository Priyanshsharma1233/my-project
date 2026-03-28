package com.myapp;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.*;
import java.nio.file.*;

@WebServlet("/download/*")
public class FileDownloadServlet extends HttpServlet {

    private static final String UPLOAD_DIR = "uploads";

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws IOException {

        String pathInfo = request.getPathInfo();
        if (pathInfo == null || pathInfo.equals("/")) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "No file specified");
            return;
        }

        String fileName = pathInfo.substring(1); // remove leading "/"

        // Block path traversal attacks
        if (fileName.contains("..") || fileName.contains("/") || fileName.contains("\\")) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN);
            return;
        }

        String appPath = getServletContext().getRealPath("");
        File file = new File(appPath + File.separator + UPLOAD_DIR + File.separator + fileName);

        if (!file.exists()) {
            response.sendError(HttpServletResponse.SC_NOT_FOUND, "File not found");
            return;
        }

        // Strip UUID prefix to get original file name
        String originalName = fileName.contains("_")
                ? fileName.substring(fileName.indexOf("_") + 1)
                : fileName;

        response.setContentType(getServletContext().getMimeType(file.getName()));
        response.setHeader("Content-Disposition", "attachment; filename=\"" + originalName + "\"");
        response.setContentLengthLong(file.length());

        // Stream the file to the browser
        try (InputStream in  = Files.newInputStream(file.toPath());
             OutputStream out = response.getOutputStream()) {
            byte[] buffer = new byte[4096];
            int bytesRead;
            while ((bytesRead = in.read(buffer)) != -1) {
                out.write(buffer, 0, bytesRead);
            }
        }
    }
}