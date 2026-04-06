package oigo.com.pe.utils.builders;

import io.appium.java_client.android.AndroidDriver;
import net.serenitybdd.core.Serenity;
import net.serenitybdd.screenplay.Actor;
import net.serenitybdd.screenplay.Task;
import net.serenitybdd.screenplay.Tasks;
import net.thucydides.core.webdriver.WebDriverFacade;
import org.openqa.selenium.WebDriver;

import java.util.Set;

public class SwitchToNativeContext implements Task {
    public static SwitchToNativeContext now() {
        return Tasks.instrumented(SwitchToNativeContext.class);
    }

    @Override
    public <T extends Actor> void performAs(T actor) {
        WebDriver baseDriver = Serenity.getDriver();

        if (baseDriver instanceof WebDriverFacade) {
            WebDriverFacade facade = (WebDriverFacade) baseDriver;
            AndroidDriver androidDriver = (AndroidDriver) facade.getProxiedDriver();

            Set<String> contextNames = androidDriver.getContextHandles();
            for (String contextName : contextNames) {
                if (contextName.contains("NATIVE")) {
                    System.out.println("NATIVE Switching to context: " + contextName);
                    androidDriver.context(contextName);
                    break;
                }
            }
        } else {
            throw new ClassCastException("Driver is not a WebDriverFacade");
        }
    }
}
