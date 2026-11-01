# GitHub Pages deployment

Workflow: .github/workflows/deploy-web.yml

1. In repository Settings > Pages > Build and deployment, select **GitHub Actions** as source.
2. Run the **Validate and deploy Godot Web** workflow (or push to main).
3. Wait for a successful build and deployment in Actions.
4. Expected URL: https://mariomarques01.github.io/gamewoood/

A green deployment is not proof of gameplay. Run `python3 tests/web_smoke.py --url https://mariomarques01.github.io/gamewoood/` and inspect its screenshots/console evidence.

This is a browser preview of the early Godot prototype; native Android/iOS builds are separate. Web exports require browser WebGL support.
