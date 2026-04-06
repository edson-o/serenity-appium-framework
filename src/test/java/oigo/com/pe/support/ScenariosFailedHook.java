package oigo.com.pe.support;

import io.cucumber.java.After;
import io.cucumber.java.Scenario;

import java.io.*;
import java.util.*;

public class ScenariosFailedHook {

    private static final Set<String> failedTags = new HashSet<>();

    static {
        Runtime.getRuntime().addShutdownHook(new Thread(ScenariosFailedHook::imprimirResumen));
    }

    @After
    public void afterScenario(Scenario scenario) {
        if (scenario.isFailed()) {
            for (String tag : scenario.getSourceTagNames()) {
                // Detecta tags que contengan dígitos al final: test2629, TC_999, @anything999
                if (tag.matches("@.*\\D*\\d+$")) {
                    failedTags.add(tag);
                }
            }
        }
    }

    private static void imprimirResumen() {
        System.out.println("\n📋 RESUMEN DE ESCENARIOS OUTLINE FALLIDOS:");

        if (failedTags.isEmpty()) {
            System.out.println("Todos los escenarios pasaron correctamente.");
        } else {
            failedTags.forEach(System.out::println);

            File file = new File("build/test-results/test/escenarios_fallidos.txt");
            File parentDir = file.getParentFile();
            if (!parentDir.exists()) {
                boolean created = parentDir.mkdirs();
                if (created) {
                    System.out.println("Carpeta creada: " + parentDir.getAbsolutePath());
                } else {
                    System.err.println("No se pudo crear la carpeta: " + parentDir.getAbsolutePath());
                }
            }

            // Guardar en archivo
            try (PrintWriter writer = new PrintWriter(file, "UTF-8")) {
                for (String tag : failedTags) {
                    writer.println(tag);
                }
                System.out.println("Archivo de resumen generado en: " + file.getAbsolutePath());
            } catch (IOException e) {
                System.err.println("Error al escribir el archivo de resumen:");
                e.printStackTrace();
            }
        }
    }

}