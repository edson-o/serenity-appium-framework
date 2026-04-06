package oigo.com.pe.utils.builders;

import io.appium.java_client.android.AndroidDriver;
import net.serenitybdd.core.Serenity;
import net.serenitybdd.screenplay.Actor;
import net.serenitybdd.screenplay.Task;
import net.thucydides.core.webdriver.WebDriverFacade;

import java.util.Optional;
import java.util.Set;

import static net.serenitybdd.screenplay.Tasks.instrumented;

public class SwitchToWebViewContext implements Task {

    public static SwitchToWebViewContext now() {
        return instrumented(SwitchToWebViewContext.class);
    }

    @Override
    public <T extends Actor> void performAs(T actor) {

        WebDriverFacade facade = (WebDriverFacade) Serenity.getDriver();
        AndroidDriver driver = (AndroidDriver) facade.getProxiedDriver();
        System.out.println("Contexto actual: " + driver.getContext());

        System.out.println("Buscando contexto WEBVIEW...");

        Set<String> contextNames = driver.getContextHandles();
        contextNames.forEach(context -> System.out.println("Contexto disponible: " + context));

        Optional<String> webviewContext = contextNames.stream()
                .filter(name -> name.toLowerCase().contains("webview"))
                .findFirst();

        if (webviewContext.isPresent()) {
            System.out.println("Cambiando a contexto: " + webviewContext.get());
            driver.context(webviewContext.get());
        } else {
            System.out.println("⚠Contexto WEBVIEW aún no disponible. Se mantiene en NATIVE_APP.");
        }

    }
}
