@AllLogin
Feature: Login

  @Automated @Happy_path @Functional_testing @Login
  Scenario Outline: [HAPPY PATH] login with email
    Given that the user is in the oigo login iframe
    When select the login option
    And select a sessiontype <typesession> then email <email> and password <password>
    Then we verify that we are in the page session with login

    Examples: Ingresar with email
      | typesession | email                       | password |
      | email       | testingpruebaoigo@gmail.com | peru2021 |
#      | facebook    | testingoigo@gmail.com       | peru2021 |
#      | google      | testingpruebaoigo@gmail.com | peru2021 |
