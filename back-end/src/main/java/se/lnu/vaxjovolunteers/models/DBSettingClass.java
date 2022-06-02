package se.lnu.vaxjovolunteers.models;

public record DBSettingClass(
        String host,
        String port,
        String database,
        String username,
        String password
) {
    public String getJDBCUrl() {
        return "jdbc:postgresql://" + host + ":" + port + "/" + database;
    }
}