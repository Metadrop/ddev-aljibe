<?php

/**
 * @file
 * Behat Feature Context file.
 */

use Behat\Behat\Context\Environment\InitializedContextEnvironment;
use Behat\Behat\Hook\Scope\BeforeScenarioScope;
use Drupal\DrupalExtension\Context\DrupalContext;

/**
 * Main project custom context.
 */
class FeatureContext extends DrupalContext {

  /**
   * Mink context.
   *
   * @var Drupal\DrupalExtension\Context\MinkContext
   */
  protected $minkContext;

  /**
   * Responsive context.
   *
   * @var \NuvoleWeb\Drupal\DrupalExtension\Context\ResponsiveContext
   */
  protected $responsiveContext;

  /**
   * Custom context parameters.
   *
   * @var array<mixed>
   */
  protected array $customParameters = [];

  /**
   * Retrieve all required sub-contexts.
   *
   * @BeforeScenario
   */
  public function gatherContexts(BeforeScenarioScope $scope) {
    $environment = $scope->getEnvironment();
    assert($environment instanceof InitializedContextEnvironment);
    $this->minkContext = $environment->getContext('Drupal\DrupalExtension\Context\MinkContext');
    $this->responsiveContext = $environment->getContext('NuvoleWeb\Drupal\DrupalExtension\Context\ResponsiveContext');
  }

  /**
   * Gets context parameters if they are defined.
   *
   * @param mixed $parameters
   *   Context parameter.
   */
  public function __construct($parameters = NULL) {
    $this->customParameters = !empty($parameters) ? $parameters : [];
  }

  /**
   * Clear cache.
   *
   * @BeforeScenario @cache-clear
   */
  public function cacheClearTag() {
    $this->assertCacheClear();
  }

  /**
   * Before scenario sets the viewport to desktop on javascript tests.
   *
   * @BeforeScenario @javascript
   */
  public function beforeSetViewportEditor() {
    $this->responsiveContext->assertDeviceScreenResize('desktop');
  }

}
