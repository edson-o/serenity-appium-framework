package oigo.com.pe.stepsdefinitions;

import io.appium.java_client.AppiumDriver;
import io.cucumber.java.Before;
import io.cucumber.java.en.And;
import io.cucumber.java.en.Given;
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;
import lombok.extern.java.Log;
import net.serenitybdd.screenplay.abilities.BrowseTheWeb;
import net.serenitybdd.screenplay.actions.Click;
import net.serenitybdd.screenplay.actors.OnStage;
import net.serenitybdd.screenplay.actors.OnlineCast;
import net.serenitybdd.screenplay.waits.WaitUntil;
import net.thucydides.core.annotations.Managed;
import oigo.com.pe.questions.ValidacionLogueo;
import oigo.com.pe.task.EnterLoginPage;
import oigo.com.pe.task.OpenOigo;
import oigo.com.pe.task.login.AutenticationOigo;
import oigo.com.pe.userinterfaces.Home;
import oigo.com.pe.userinterfaces.Login;
import org.openqa.selenium.WebDriver;

import static net.serenitybdd.screenplay.GivenWhenThen.seeThat;
import static net.serenitybdd.screenplay.actors.OnStage.theActorCalled;
import static net.serenitybdd.screenplay.actors.OnStage.theActorInTheSpotlight;
import static net.serenitybdd.screenplay.matchers.WebElementStateMatchers.isVisible;
import static org.hamcrest.Matchers.containsString;

public class LoginStepDefinitions {

    @Before
    public void setTheStage() {
        OnStage.setTheStage(new OnlineCast());
    }

    @Given("^that the (.*) is in the oigo login iframe$")
    public void userloginoigo(String user) {
            theActorCalled(user).attemptsTo(Click.on(Login.INPUT_GOO_PASS));
    }

    @When("^select the login option$")
    public void selectloginoption() {
        theActorInTheSpotlight().attemptsTo(
                WaitUntil.the(Login.BTN_SESSION, isVisible()).forNoMoreThan(60).seconds(),
                new EnterLoginPage()
        );
    }

    @And("^select a sessiontype (.*) then email (.*) and password (.*)$")
    public void selectsessiontype(String sessiontype, String email, String password) {
        theActorInTheSpotlight().attemptsTo(
                AutenticationOigo.with(sessiontype, email, password)
        );
    }

    @Then("^we verify that we are in the page session with login$")
    public void weverifythatweareinthepagesession() {
        theActorInTheSpotlight().attemptsTo(
                WaitUntil.the(Home.LABEL_TEXTHOME, isVisible()).forNoMoreThan(60).seconds()
        );
        theActorInTheSpotlight().should(
                seeThat("Welcome", ValidacionLogueo.home(), containsString("¡Hola,"))
        );
    }


}
