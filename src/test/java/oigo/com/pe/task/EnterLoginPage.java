package oigo.com.pe.task;

import net.serenitybdd.screenplay.Actor;
import net.serenitybdd.screenplay.Task;
import net.serenitybdd.screenplay.actions.Click;
import net.thucydides.core.annotations.Step;
import oigo.com.pe.userinterfaces.Login;


public class EnterLoginPage implements Task {

    @Override
    @Step("{0} click login")
    public <T extends Actor> void performAs(T actor) {
        actor.attemptsTo(
                Click.on(Login.BTN_SESSION)
        );

    }


}
