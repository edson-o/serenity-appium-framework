package oigo.com.pe.task;

import io.appium.java_client.remote.MobileCapabilityType;
import net.serenitybdd.core.environment.EnvironmentSpecificConfiguration;
import net.serenitybdd.screenplay.Actor;
import net.serenitybdd.screenplay.Task;
import net.serenitybdd.screenplay.actions.Open;
import net.thucydides.core.annotations.Step;
import net.thucydides.core.util.EnvironmentVariables;
import org.openqa.selenium.remote.DesiredCapabilities;

import java.io.File;

import static net.serenitybdd.screenplay.Tasks.instrumented;

public class OpenOigo implements Task {

    EnvironmentVariables environmentVariables;

    private final String url;

    public OpenOigo(String url) {
        this.url = url;
    }

    @Override
    @Step("{0} Start the page #url")
    public <T extends Actor> void performAs(T actor) {
//        DesiredCapabilities capa = new DesiredCapabilities();
        /*******************   CODIGO PARA OBTENER EL APK E INSTALARLO EN EL EMULADOR - INICIO *******************/
//        File file = new File("src/test/resources/data/");
//        File ubication = new File(file, "oigo-dev1.apk");
//        capa.setCapability(MobileCapabilityType.APP, ubication.getAbsolutePath());
        /*****************   CODIGO PARA OBTENER EL APK E INSTALARLO EN EL EMULADOR - FIN *******************/
    }

    public static Task theLoginOigoPage() {
      //  String url = "oigo.page";
        return instrumented(OpenOigo.class);
    }

}
