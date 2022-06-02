package se.lnu.vaxjovolunteers;

import io.javalin.Javalin;
import io.javalin.plugin.openapi.OpenApiOptions;
import io.javalin.plugin.openapi.OpenApiPlugin;
import io.javalin.plugin.openapi.ui.ReDocOptions;
import io.javalin.plugin.openapi.ui.SwaggerOptions;
import io.swagger.v3.oas.models.info.Info;

public class Main {

    // Change these for now, will be changed to config


    public static void main(String[] args) {
        try (Javalin app = Javalin.create(config -> {
            config.registerPlugin(new OpenApiPlugin(getOpenApiOptions()));
        }).start(SettingsTemporarily.WEB_PORT)) {
            new App(app);
            while(true) {

            }
        }
    }

    private static OpenApiOptions getOpenApiOptions() {
        Info applicationInfo = new Info()
                .version("1.0")
                .description("My Application");
        return new OpenApiOptions(applicationInfo).path("/swagger-docs").defaultDocumentation(doc -> { doc.json("500", Error.class); }) // Lambda that will be applied to every documentation
                // .activateAnnotationScanningFor("com.my.package") // Activate annotation scanning (Required for annotation api with static java methods)
                .swagger(new SwaggerOptions("/swagger").title("My Swagger Documentation")) // Activate the swagger ui
                .reDoc(new ReDocOptions("/redoc").title("My ReDoc Documentation"));
    }
}