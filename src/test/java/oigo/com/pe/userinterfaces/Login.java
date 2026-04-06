package oigo.com.pe.userinterfaces;

import net.serenitybdd.screenplay.targets.Target;
import org.openqa.selenium.By;


public class Login {

    public static final Target BTN_SESSION = Target.the("Click Session").locatedBy("//button[text()=' Iniciar Sesión ']");
    public static final Target ENTER_EMAIL = Target.the("Enter Email").locatedBy("//input[@type='email']");
    public static final Target ENTER_PASS = Target.the("Enter Password").locatedBy("//input[@type='password']");
    public static final Target BTN_START = Target.the("Click Start").locatedBy("//button[text()=' Comenzar ']");
    public static final Target BTN_FACEBOOK = Target.the("Click Start Facebook").locatedBy("//button[text()=' Continuar con Facebook ']");
    public static final Target BTN_GOOGLE = Target.the("Click Start Google").locatedBy("//button[text()=' Continuar con Google ']");

    public static final Target INPUT_GOO_EMAIL = Target.the("Input Email").locatedBy("//input[@type='email']");
    public static final Target BTN_GOO_NEXT = Target.the("Click Next").locatedBy("//div[@id='identifierNext']/div/button");
    public static final Target INPUT_GOO_PASS = Target.the("Input Password").located(By.id("com.streann.crp.develop:id/ivOnboardingItemImageLogo"));
    public static final Target BTN_GOO_NEXTPASS = Target.the("Click Next").locatedBy("//div[@id='passwordNext']/div/button");

    public static final Target INPUT_FACE_EMAIL = Target.the("Input Email").locatedBy("//input[@id='email']");
    public static final Target INPUT_FACE_PASS = Target.the("Input Password").locatedBy("//input[@id='pass']");
    public static final Target BTN_LOGIN_FACEBOOK = Target.the("Click Next").locatedBy("//input[@name='login']");


}
