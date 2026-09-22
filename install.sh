# Execute in current directory. Make sure uv is installed (see https://github.com/astral-sh/uv)

uv init .
uv python install
uv add pandas numpy matplotlib seaborn jupyter scikit-learn statsmodels
