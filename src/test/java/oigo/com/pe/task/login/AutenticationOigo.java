package oigo.com.pe.task.login;

import net.serenitybdd.screenplay.Actor;
import net.serenitybdd.screenplay.Task;
import net.serenitybdd.screenplay.actions.Click;
import net.serenitybdd.screenplay.actions.Enter;
import net.serenitybdd.screenplay.waits.WaitUntil;
import net.thucydides.core.annotations.Step;
import oigo.com.pe.task.SwitchToNewWindow;
import oigo.com.pe.userinterfaces.Login;

import static net.serenitybdd.screenplay.Tasks.instrumented;
import static net.serenitybdd.screenplay.matchers.WebElementStateMatchers.isVisible;

public class AutenticationOigo implements Task {

    private String sessiontype;
    private String email;
    private String password;

    public AutenticationOigo(String sessiontype, String email, String password) {
        this.sessiontype = sessiontype;
        this.email = email;
        this.password = password;
    }

    public static AutenticationOigo with(String sessiontype, String email, String password) {
        return instrumented(AutenticationOigo.class, sessiontype, email, password);
    }


    @Override
    @Step("{0} autentication oigo")
    public <T extends Actor> void performAs(T actor) {
        switch (sessiontype) {
            case "email":
                actor.attemptsTo(
                        Enter.theValue(email).into(Login.ENTER_EMAIL),
                        Enter.theValue(password).into(Login.ENTER_PASS),
                        Click.on(Login.BTN_START)
                );
                break;
            case "facebook":
                actor.attemptsTo(
                        Click.on(Login.BTN_FACEBOOK)
                );
                actor.attemptsTo(SwitchToNewWindow.switchToNewTab());
                actor.attemptsTo(
                        WaitUntil.the(Login.INPUT_FACE_EMAIL, isVisible()).forNoMoreThan(60).seconds(),
                        Enter.theValue(email).into(Login.INPUT_FACE_EMAIL),
                        Enter.theValue(password).into(Login.INPUT_FACE_PASS),
                        Click.on(Login.BTN_LOGIN_FACEBOOK)
                );
                break;
            case "google":
                actor.attemptsTo(
                        Click.on(Login.BTN_GOOGLE)
                );
                actor.attemptsTo(SwitchToNewWindow.switchToNewTab());
                actor.attemptsTo(
                        WaitUntil.the(Login.INPUT_GOO_EMAIL, isVisible()).forNoMoreThan(60).seconds(),
                        Enter.theValue(email).into(Login.INPUT_GOO_EMAIL),
                        Click.on(Login.BTN_GOO_NEXT),
                        WaitUntil.the(Login.INPUT_GOO_PASS, isVisible()).forNoMoreThan(60).seconds(),
                        Enter.theValue(password).into(Login.INPUT_GOO_PASS),
                        Click.on(Login.BTN_GOO_NEXT)
                );

                break;
        }

    }
}
