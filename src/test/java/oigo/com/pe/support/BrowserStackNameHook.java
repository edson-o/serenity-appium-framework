package oigo.com.pe.support;

import io.cucumber.java.After;
import io.cucumber.java.AfterStep;
import io.cucumber.java.Scenario;
import net.serenitybdd.core.environment.WebDriverConfiguredEnvironment;
import net.thucydides.core.webdriver.ThucydidesWebDriverSupport;
import org.openqa.selenium.JavascriptExecutor;
import org.openqa.selenium.remote.RemoteWebDriver;

import java.text.Normalizer;

public class BrowserStackNameHook {

    private static final ThreadLocal<Boolean> renamed = ThreadLocal.withInitial(() -> false);

    private boolean isBrowserStackEnv() {
        var envVars = WebDriverConfiguredEnvironment.getEnvironmentVariables();
        String env = envVars.getProperty("environment", "");
        // ejemplo: browserstack, browserstack-qa, etc.
        return env.toLowerCase().startsWith("browserstack");
    }

    private RemoteWebDriver getRemoteDriverSafe() {
        try {
            var d = ThucydidesWebDriverSupport.getProxiedDriver();
            if (d instanceof RemoteWebDriver) {
                RemoteWebDriver r = (RemoteWebDriver) d;
                // si aún no hay sessionId, todavía no está “arriba”
                if (r.getSessionId() != null) return r;
            }
        } catch (Exception ignored) {}
        return null;
    }

    private String buildFullName(Scenario scenario) {
        String name = Normalizer.normalize(scenario.getName(), Normalizer.Form.NFD)
                .replaceAll("\\p{InCombiningDiacriticalMarks}+", "");

        // En Cucumber 7.x devuelve Collection<String>
        String tags = String.join(" ", scenario.getSourceTagNames());

        return (name + " - " + tags).replace("\"", "'");
    }


    // ✅ Se ejecuta en el primer step real (driver ya existe), SOLO 1 VEZ
    @AfterStep(order = 1)
    public void setSessionNameOnce(Scenario scenario) {
        if (!isBrowserStackEnv()) return;
        if (Boolean.TRUE.equals(renamed.get())) return;

        RemoteWebDriver driver = getRemoteDriverSafe();
        if (driver == null) return;

        try {
            String fullName = buildFullName(scenario);

            ((JavascriptExecutor) driver).executeScript(
                    "browserstack_executor: {\"action\":\"setSessionName\",\"arguments\":{\"name\":\"" + fullName + "\"}}"
            );

            renamed.set(true);
            System.out.println("✅ BrowserStack sessionName seteado: " + fullName);
        } catch (Exception e) {
            System.out.println("⚠️ No se pudo setear sessionName: " + e.getMessage());
        }
    }

    // ✅ Status al final (antes de que Serenity destruya el driver)
    @After(order = 999)
    public void setBrowserStackStatus(Scenario scenario) {
        if (!isBrowserStackEnv()) return;

        try {
            RemoteWebDriver driver = getRemoteDriverSafe();
            if (driver == null) return;

            String status = scenario.isFailed() ? "failed" : "passed";
            String reason = scenario.isFailed() ? "Escenario fallido" : "Escenario exitoso";

            ((JavascriptExecutor) driver).executeScript(
                    "browserstack_executor: {\"action\":\"setSessionStatus\",\"arguments\":{\"status\":\""
                            + status + "\",\"reason\":\"" + reason + "\"}}"
            );
        } catch (Exception ignored) {
        } finally {
            renamed.remove();
        }
    }
}
