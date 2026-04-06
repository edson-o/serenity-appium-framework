package oigo.com.pe.support;

import io.cucumber.java.After;
import io.cucumber.java.Scenario;

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.util.*;

public class ScenariosStatusHook {

    static {
        Runtime.getRuntime().addShutdownHook(new Thread(() -> {
            imprimirResumen();
        }));
    }

    private static final Map<String, List<Boolean>> scenarioStatusByTestCase = new LinkedHashMap<>();

    @After
    public void afterScenario(Scenario scenario) {
        String testCaseId = extractTestCaseId(scenario.getSourceTagNames());
        if (testCaseId != null) {
            scenarioStatusByTestCase
                    .computeIfAbsent(testCaseId, k -> new ArrayList<>())
                    .add(scenario.isFailed());
        }

        if (scenario.getSourceTagNames().contains("@last")) {
            imprimirResumen();
        }
    }

    private String extractTestCaseId(Collection<String> tags) {
        for (String tag : tags) {
            if (tag.matches("@?(TestCaseId:|TC|Caso)?[0-9]{3,6}")) {
                return tag.startsWith("@") ? tag : "@" + tag;
            }
        }
        return null;
    }

    public static void imprimirResumen() {
        System.out.println("resumen_errores:");
        File file = new File("build/test-results/test/estado_de_escenarios.txt");
        File parentDir = file.getParentFile();
        if (!parentDir.exists()) {
            boolean created = parentDir.mkdirs();
            if (created) {
                System.out.println("Carpeta creada: " + parentDir.getAbsolutePath());
            } else {
                System.err.println("No se pudo crear la carpeta: " + parentDir.getAbsolutePath());
            }
        }

        try (BufferedWriter writer = new BufferedWriter(new FileWriter(file))) {
            for (Map.Entry<String, List<Boolean>> entry : scenarioStatusByTestCase.entrySet()) {
                String testCaseId = entry.getKey();
                List<Boolean> results = entry.getValue();

                long failed = results.stream().filter(r -> r).count();
                int total = results.size();
                String resumen = testCaseId + " - " + total + " tests completed, " + failed + " failed";

                System.out.println(resumen);
                writer.write(resumen);
                writer.newLine();
            }
        } catch (IOException e) {
            System.err.println("Error al escribir el resumen_final.txt: " + e.getMessage());
            e.printStackTrace();
        }
    }

}
