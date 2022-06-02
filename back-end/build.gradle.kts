import org.jooq.meta.jaxb.ForcedType
import org.jooq.meta.jaxb.Logging

plugins {
    id("java")
    id("application")
    id("nu.studer.jooq") version "7.1.1"
    id("com.github.johnrengelman.shadow") version "7.1.2"
}

group = "se.lnu"
version = "1.0-SNAPSHOT"

repositories {
    mavenCentral()
}

application {
    mainClass.set("se.lnu.vaxjovolunteers.Main")
}

tasks.withType<Jar> {
    manifest {
        attributes["Main-Class"] = "se.lnu.vaxjovolunteers.Main"
    }
    duplicatesStrategy = DuplicatesStrategy.INCLUDE
}


dependencies {
    testImplementation("org.junit.jupiter:junit-jupiter-api:5.8.2")
    testRuntimeOnly("org.junit.jupiter:junit-jupiter-engine:5.8.2")
    // Web framework
    implementation("io.javalin", "javalin", "4.5.0")
    implementation("io.javalin", "javalin-openapi", "4.5.0")
    implementation("javax.xml.bind", "jaxb-api", "2.3.1")
    // Database related
    implementation("org.jooq", "jooq", "3.16.6")
    implementation("com.zaxxer", "HikariCP", "5.0.1")
    implementation("org.postgresql", "postgresql", "42.3.5")
    jooqGenerator("org.postgresql:postgresql:42.3.5")
    // Logging related
    implementation("ch.qos.logback", "logback-classic", "1.2.3")
    implementation("com.fasterxml.jackson.core:jackson-core:2.13.2")
    implementation("com.fasterxml.jackson.core:jackson-databind:2.13.2.2")
    implementation("com.fasterxml.jackson.core:jackson-annotations:2.13.2")
    implementation("com.fasterxml.jackson.datatype:jackson-datatype-jsr310:2.13.2")
    implementation("com.squareup.okhttp3:okhttp:4.9.3")
}

jooq {
    version.set("3.16.4")  // default (can be omitted)
    edition.set(nu.studer.gradle.jooq.JooqEdition.OSS)  // default (can be omitted)

    configurations {
        create("main") {  // name of the jOOQ configuration
            generateSchemaSourceOnCompilation.set(true)  // default (can be omitted)

            jooqConfiguration.apply {
                logging = Logging.WARN
                // #TODO: CHANGE THIS IF THE GRADLE BUILD FAILS, SHOULD BE SAME AS TEMPORARILYSETTINGS.JAVA
                jdbc.apply {
                    driver = "org.postgresql.Driver"
                    url = "jdbc:postgresql://localhost:5432/vaxjo_volunteers"
                    user = "vaxjo_volunteers"
                    password = "vaxjo_volunteers"
                }
                generator.apply {
                    name = "org.jooq.codegen.DefaultGenerator"
                    database.apply {
                        name = "org.jooq.meta.postgres.PostgresDatabase"
                        inputSchema = "public"
                        forcedTypes.addAll(listOf(
                            ForcedType().apply {
                                name = "varchar"
                                includeExpression = ".*"
                                includeTypes = "JSONB?"
                            },
                            ForcedType().apply {
                                name = "varchar"
                                includeExpression = ".*"
                                includeTypes = "INET"
                            }
                        ))
                    }
                    generate.apply {
                        isDeprecated = false
                        isRecords = true
                        isImmutablePojos = true
                        isFluentSetters = true
                    }
                    target.apply {
                        packageName = "se.lnu.vaxjovolunteers.jooq"
                        directory = "build/generated-src/jooq/main"  // default (can be omitted)
                    }
                    strategy.name = "org.jooq.codegen.DefaultGeneratorStrategy"
                }
            }
        }
    }
}

tasks.getByName<Test>("test") {
    useJUnitPlatform()
}

