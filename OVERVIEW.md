# 🧭 Purpose & Scope

Pyan3 is an offline static analysis tool for Python that builds dependency graphs without executing code. It helps developers understand structure, call flow, and module coupling in medium-to-large codebases where manual inspection is expensive.

Primary users are Python developers, maintainers, architects, and technical writers who need fast architectural visibility for debugging, refactoring, onboarding, and documentation.

It matters because it provides low-risk, environment-independent insight: no runtime instrumentation, no production-like inputs, and no need to trigger every code path to understand relationships.

| Purpose | Scope | Notes |
|---|---|---|
| Generate static call graphs | Functions, methods, classes, defines/uses edges | Approximate analysis by design; prioritizes practical signal over perfect precision |
| Generate module dependency graphs | Import relationships and cycle detection | Separate mode via `--module-level` and `create_modulegraph()` |
| Provide output for visualization and automation | `dot`, `svg`, `html`, `yed`, `tgf`, `text` | Graphviz required for `svg`/`html`; `text` is useful for AI/automation pipelines |
| Support CLI and Python API consumption | `pyan3` CLI and `pyan` package APIs | Works on Python 3.10-3.14; packaging via `pyproject.toml` |

## 🏗️ Architecture

The codebase is organized around a clear pipeline:

1. Expand/resolve source inputs.
2. Analyze AST and symbol/scope relationships.
3. Build an internal graph model.
4. Transform into a visualization-oriented graph.
5. Serialize via format-specific writers (or emit text dependencies).

Two analysis tracks share output infrastructure:
- **Call graph track**: `analyzer.py` + `main.py`.
- **Module graph track**: `modvis.py`.

```mermaid
flowchart LR
    UC[User Code<br/>Python files / globs / directories] --> API[Public API<br/>pyan.create_callgraph()<br/>pyan.create_modulegraph()<br/>pyan3 CLI]

    API --> R1[Readers / Analyzers<br/>CallGraphVisitor in analyzer.py]
    API --> R2[Readers / Analyzers<br/>ImportVisitor in modvis.py]

    R1 --> U1[Utilities<br/>anutils.py<br/>scope + source expansion + MRO helpers]
    R2 --> U1

    R1 --> D1[Data Model<br/>node.py Node + Flavor<br/>defines/uses relations]
    R2 --> D1

    D1 --> V1[Visual Layer<br/>visgraph.py VisualGraph + Colorizer]
    V1 --> W1[Writers<br/>writers.py Dot/SVG/HTML/Yed/TGF/Text]

    W1 --> O1[Outputs<br/>dot/svg/html/yed/tgf/text]
    API --> S1[Sphinx Extension<br/>sphinx.py callgraph directive]
```

| Component | Description |
|---|---|
| `pyan/main.py` | CLI entrypoint and `create_callgraph()` API; option parsing, filtering, writer dispatch |
| `pyan/analyzer.py` | Core call-graph static analyzer (`CallGraphVisitor`) with multi-pass resolution and graph querying |
| `pyan/modvis.py` | Module-level import dependency analyzer (`ImportVisitor`) plus cycle detection and dedicated CLI mode |
| `pyan/anutils.py` | Utility layer for scope handling, AST naming/canonicalization helpers, source expansion, and MRO support |
| `pyan/node.py` | Core entity model (`Node`, `Flavor`) used to represent graph nodes consistently |
| `pyan/visgraph.py` | Visualization-oriented graph abstraction and coloring/grouping transformations |
| `pyan/writers.py` | Output adapters to Graphviz/yEd/text targets; single abstraction for multiple formats |
| `pyan/sphinx.py` | Sphinx directive integration for embedding generated call graphs in docs |
| `pyan/callgraph.html` | Jinja2 template for interactive HTML graph rendering |
| `tests/` | Regression, feature, writer, analyzer, module-graph, and coverage tests across Python syntax versions |

## ⚖️ Pain Points / Trade-offs

The project intentionally accepts approximation to keep analysis practical and fast. The main risks are concentrated in resolution complexity and places where Python dynamism exceeds static inference.

| Area | Impact | Notes |
|---|---|---|
| Static approximation vs Python dynamism | Medium | Runtime behaviors (dynamic imports, metaprogramming, monkey patching) can produce missing or extra edges |
| Large, central analyzer (`analyzer.py`) | High | High cognitive load and change risk; many intertwined responsibilities (scopes, binding, filtering, post-processing) |
| Multi-pass + postprocessing pipeline | High | Correctness depends on operation order (imports, wildcard contraction/expansion, inherited edge culling) |
| Wildcard and unresolved name handling | Medium | Necessary for resilience, but can still create ambiguity in edge interpretation |
| Graphviz dependency for rich outputs | Medium | `svg`/`html` workflows fail without external `dot`; user experience depends on system setup |
| Exhaustive cycle detection in module mode | Medium | Useful but may become expensive/noisy on large dependency graphs |
| Mixed terminology around “node” concepts | Low | Potential confusion between AST nodes, analysis nodes, and visual nodes during onboarding |

## 🚀 Potential Enhancements

| Priority | Idea | Component | Quick-Win? |
|---|---|---|---|
| High | Split `CallGraphVisitor` into focused phases (collector, resolver, postprocessor) with explicit interfaces | `analyzer.py` | No |
| High | Add edge confidence metadata (`certain`, `inferred`, `wildcard-expanded`) and surface in text/graph outputs | `analyzer.py`, `visgraph.py`, `writers.py` | No |
| High | Introduce focused benchmark suite for large repositories and enforce performance budgets in CI | `tests/`, CI workflows | No |
| Medium | Add machine-readable JSON output format for downstream tooling and LLM pipelines | `writers.py`, `main.py`, `modvis.py` | Yes |
| Medium | Improve diagnostics mode that explains why a specific edge exists (traceable provenance) | `analyzer.py`, CLI | No |
| Medium | Create architecture-focused docs page with “analysis lifecycle” and “extension points” | docs/README set | Yes |
| Low | Add optional plugin hooks for custom filters or node enrichment | API surface | No |
| Low | Provide first-party container/devcontainer configuration for reproducible onboarding | repository root | Yes |

## 🧪 Onboarding Guidance

### Local setup (recommended)

1. **Install uv**
   ```powershell
   irm https://astral.sh/uv/install.ps1 | iex
   uv --version
   ```
   Expected output: a version string such as `uv 0.x.y`.

2. **Create environment and install dev/test dependencies**
   ```powershell
   uv sync --extra test
   ```
   Expected output: dependency resolution plus environment/package installation messages.

3. **Verify CLI is available**
   ```powershell
   uv run pyan3 --help
   ```
   Expected output: usage text including output mode flags (`--dot`, `--svg`, `--html`, etc.).

4. **Run tests**
   ```powershell
   uv run pytest tests/ -v
   ```
   Expected output: collected tests and pass/fail summary.

5. **Run lint**
   ```powershell
   uv run ruff check .
   ```
   Expected output: either `All checks passed!` or a list of lint findings.

### Container setup (no first-party Dockerfile provided)

Use an ephemeral Python container and bind mount the repository:

```bash
docker run --rm -it -v "$PWD:/workspace" -w /workspace python:3.14 bash
python -m pip install --upgrade pip uv
uv sync --extra test
uv run pytest tests/ -v
uv run pyan3 --help
```

Expected output mirrors local setup (installation logs, test summary, CLI help).  
If you need `svg`/`html` outputs inside container, install Graphviz (`dot`) in the container first.

### Quick usage examples

```bash
# Call graph (DOT)
uv run pyan3 pyan/ --dot --colored --no-defines --concentrate --file out.dot

# Module dependency graph
uv run pyan3 --module-level pyan/ --dot -c -e --file modules.dot

# API usage
python -c "import pyan; print(pyan.create_callgraph('pyan/**/*.py', format='text')[:500])"
```

### Tips for exploring/extending

- Start from `pyan/main.py` to understand user-facing flow and mode dispatch.
- Study `pyan/analyzer.py` and `pyan/modvis.py` separately; they solve different graph problems.
- Use `tests/test_features.py`, `tests/test_regressions.py`, and `tests/test_modvis.py` as executable behavior documentation.
- Extend outputs in `pyan/writers.py` only after validating shape/semantics in `visgraph.py`.
- Add regression tests first when changing wildcard/import resolution logic.

## 🎨 Visual Elements

- Emojis are intentionally used in section headers for scanability.
- Tables are Markdown-native for easy rendering in IDEs and repository viewers.
- Mermaid is used for architecture communication and can be pasted into docs systems that support Mermaid blocks.
