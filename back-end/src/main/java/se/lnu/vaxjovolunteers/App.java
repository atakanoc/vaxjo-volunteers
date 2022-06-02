package se.lnu.vaxjovolunteers;

import io.javalin.Javalin;
import se.lnu.vaxjovolunteers.controller.DatabaseManager;
import se.lnu.vaxjovolunteers.models.DBSettingClass;
import se.lnu.vaxjovolunteers.routes.Routes;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import static se.lnu.vaxjovolunteers.SettingsTemporarily.*;


public class App {
    private final Logger log = LoggerFactory.getLogger(App.class);
    private final DatabaseManager databaseManager;

    public App(Javalin app) {
        databaseManager = new DatabaseManager(new DBSettingClass(DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASS));

        new Routes(app, databaseManager);
    }
}
