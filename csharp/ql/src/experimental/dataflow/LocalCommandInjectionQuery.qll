/**
 * Provides a taint-tracking configuration for reasoning about local command injection vulnerabilities.
 */

import csharp
private import semmle.code.csharp.security.dataflow.flowsources.Local
private import semmle.code.csharp.frameworks.system.Diagnostics
private import semmle.code.csharp.security.Sanitizers

/**
 * A source specific to command injection vulnerabilities.
 */
abstract class Source extends DataFlow::Node { }

/**
 * A sink for command injection vulnerabilities.
 */
abstract class Sink extends DataFlow::ExprNode { }

/**
 * A sanitizer for user input treated as code vulnerabilities.
 */
abstract class Sanitizer extends DataFlow::ExprNode { }

/**
 * A taint-tracking configuration for command injection vulnerabilities.
 */
module LocalCommandInjectionConfig implements DataFlow::ConfigSig {
  /**
   * Holds if `source` is a relevant data flow source.
   */
  predicate isSource(DataFlow::Node source) { source instanceof Source }

  /**
   * Holds if `sink` is a relevant data flow sink.
   */
  predicate isSink(DataFlow::Node sink) { sink instanceof Sink }

  /**
   * Holds if data flow through `node` is prohibited. This completely removes
   * `node` from the data flow graph.
   */
  predicate isBarrier(DataFlow::Node node) { node instanceof Sanitizer }
}

/**
 * A taint-tracking module for local command injection vulnerabilities.
 */
module LocalCommandInjection = TaintTracking::Global<LocalCommandInjectionConfig>;

/** A source of local user input. */
class LocalSource extends Source instanceof LocalFlowSource { }

/**
 * A sink in `System.Diagnostic.Process` or its related classes.
 */
class SystemProcessCommandInjectionSink extends Sink {
  SystemProcessCommandInjectionSink() {
    // Arguments passed directly to the `System.Diagnostics.Process.Start` method
    exists(SystemDiagnosticsProcessClass processClass |
      this.getExpr() = processClass.getAStartMethod().getAParameter().getAnAssignedArgument()
    )
    or
    // Values set on a `System.Diagnostics.ProcessStartInfo` class
    exists(SystemDiagnosticsProcessStartInfoClass startInfoClass |
      this.getExpr() = startInfoClass.getAConstructor().getACall().getAnArgument()
      or
      exists(Property p |
        p = startInfoClass.getArgumentsProperty() or
        p = startInfoClass.getFileNameProperty() or
        p = startInfoClass.getWorkingDirectoryProperty()
      |
        this.getExpr() = p.getSetter().getParameter(0).getAnAssignedArgument()
      )
    )
  }
}

private class SimpleTypeSanitizer extends Sanitizer, SimpleTypeSanitizedExpr { }

private class GuidSanitizer extends Sanitizer, GuidSanitizedExpr { }
