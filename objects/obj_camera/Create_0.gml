port = {
    width : 1280,
    height : 720,
    aspect : 1,
    
    center : false,
    
    // Update the canvas every step
    Update : function() {
        aspect = width / height;
        
        if ( DESKTOP ) {
            // Centering the canvas
            if ( center ) {
                window_center();
                center = false;
            }
            
            // Resizing the canvas
            if ( window_get_width() != width || window_get_height() != height ) {
                window_set_size(width, height);
                surface_resize(application_surface, width, height);
                center = true;
            }
        }
        
        if ( BROWSER ) {
            // Centering the canvas
            if ( center ) {
                window_center();
                center = false;
            }
            
            // Resizing the canvas
            if ( browser_width != width || browser_width != height ) {
                width = browser_width; height = browser_height;
                window_set_size(width, height);
                surface_resize(application_surface, width, height);
                center = true;
            }
        }
    }
};

view = {
    x : 0,
    y : 0,
    z : -10,
    width : 480,
    height : 270,
    aspect : 1,
    scale : .7,
	fixedWidth : 1,
	fixedHeight : 1,
    
    // Update the view every step
    Update : function(canvas) {
        // Resize the view
        aspect = canvas.width / canvas.height;
        if ( true ) {
            fixedWidth = width;
            fixedHeight = width / aspect;
        } else {
            fixedHeight = height;
            fixedWidth = height * aspect;
        }
        
        var cam = view_camera[0];
        camera_set_view_mat(cam, matrix_build_lookat(x, y, z, x, y, z + 1, 0, -1, 0));
        camera_set_proj_mat(cam, matrix_build_projection_ortho(-fixedWidth * scale, -fixedHeight * scale, 0.001, 10000));
        camera_apply(cam);
    }
};
