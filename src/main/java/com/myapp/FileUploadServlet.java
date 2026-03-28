package com.myapp;

import jakarta.servlet.*;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.*;
import java.nio.file.*;
import java.util.UUID;

@WebServlet("/upload")
@MultipartConfig(
        maxFileSize    = 50 * 1024 * 1024,   // 50 MB per file
        maxRequestSize = 55 * 1024 * 1024    // 55 MB total
)
public class FileUploadServlet extends HttpServlet {

    private static final String UPLOAD_DIR = "uploads";

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // Create uploads folder if it doesn't exist
        String appPath = getServletContext().getRealPath("");
        String uploadPath = appPath + File.separator + UPLOAD_DIR;
        File uploadDir = new File(uploadPath);
        if (!uploadDir.exists()) uploadDir.mkdirs();

        // Get the uploaded file
        Part filePart = request.getPart("file");
        if (filePart == null) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            response.getWriter().write("{\"error\":\"No file received\"}");
            return;
        }

        String originalName = Paths.get(filePart.getSubmittedFileName())
                .getFileName().toString();

        // Check allowed file types
        if (!isAllowedType(originalName)) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            response.setContentType("application/json");
            response.getWriter().write("{\"error\":\"File type not allowed\"}");
            return;
        }

        // Save with unique name to avoid overwriting
        String uniqueName = UUID.randomUUID() + "_" + originalName;
        filePart.write(uploadPath + File.separator + uniqueName);

        // Return JSON with download URL and original file name
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        response.getWriter().write(
                "{\"url\":\"download/" + uniqueName + "\",\"name\":\"" + originalName + "\"}"
        );
    }

    private boolean isAllowedType(String fileName) {
        String f = fileName.toLowerCase();
        return f.endsWith(".jpg")  || f.endsWith(".jpeg") ||
                f.endsWith(".png")  || f.endsWith(".gif")  ||
                f.endsWith(".pdf")  || f.endsWith(".txt")  ||
                f.endsWith(".zip")  || f.endsWith(".docx") ||
                f.endsWith(".mp4")  || f.endsWith(".mp3")  ||
                f.endsWith(".xlsx") || f.endsWith(".pptx");
    }
}