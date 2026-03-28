# Contributors

Thank you to everyone who has contributed to this project.

---

## Developers

| Name                      | Role                | Profile                                                            |
| ------------------------- | ------------------- | ------------------------------------------------------------------ |
| Fernando Pinto Villarroel | Creator & Developer | [LinkedIn](https://www.linkedin.com/in/fernando-pinto-villarroel/) |

---

## How to Contribute

Contributions are welcome. Whether it is a bug report, a feature suggestion, or a code change, all thoughtful input is appreciated.

### Reporting Issues

Open an issue on GitHub with a clear title, a description of the problem or suggestion, and steps to reproduce if applicable. Include your device model and Android version when reporting bugs.

### Submitting a Pull Request

1. Clone the repository to your computer
2. Create a branch from `main` with a descriptive name (e.g., `fix/villager-mood`, `feat/new-building-type`)
3. Make your changes following the conventions described below
4. Test your changes on a physical device or emulator
5. Push your commits and open a pull request with a clear description of what was changed and why
6. Assign Fernando Pinto Villarroel for review

### Code Conventions

This project follows these conventions — please respect them in any contribution:

<table>
  <thead>
    <tr>
      <th>Rule</th>
      <th>Details</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><strong>Language</strong></td>
      <td>All code, variable names, comments, and commit messages must be in <strong>English</strong></td>
    </tr>
    <tr>
      <td><strong>Dart</strong></td>
      <td>Follow standard Dart conventions and linting rules. Run <code>flutter analyze</code> before submitting</td>
    </tr>
    <tr>
      <td><strong>Game rendering</strong></td>
      <td>All game rendering must use the <strong>Flame Engine</strong> — do not use plain Flutter widgets for in-game elements</td>
    </tr>
    <tr>
      <td><strong>No server-side storage</strong></td>
      <td>All user data must remain on-device in the local SQLite database — no external API calls for data storage</td>
    </tr>
    <tr>
      <td><strong>State management</strong></td>
      <td>Use existing Provider classes (<code>VillageProvider</code>, <code>BookProvider</code>) — create new providers only if necessary</td>
    </tr>
    <tr>
      <td><strong>Game constants</strong></td>
      <td>All balance values (costs, timers, XP) must be defined in <code>lib/config/game_constants.dart</code> — no magic numbers in game logic</td>
    </tr>
    <tr>
      <td><strong>Database changes</strong></td>
      <td>Schema changes require a migration in <code>lib/data/database_helper.dart</code> to avoid breaking existing users</td>
    </tr>
    <tr>
      <td><strong>Assets</strong></td>
      <td>All sprites and images go in <code>assets/images/</code> and must follow the existing kawaii pastel art style</td>
    </tr>
  </tbody>
</table>

### Running the Project Locally

See the [Getting Started](README.md#getting-started) section in the README.

### Static Analysis

Before submitting, verify there are no Dart analysis issues:

```bash
cd my_reading_town
flutter analyze
```

---

## License Note

By submitting a contribution, you agree to the terms outlined in the [LICENSE.md](LICENSE.md). In summary, you grant the copyright holder an irrevocable right to use, modify, and distribute your contribution under this license.

---

_This file will be updated as new contributors join the project._
