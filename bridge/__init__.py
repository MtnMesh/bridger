import sentry_sdk
from dotenv import load_dotenv

load_dotenv()

sentry_sdk.init(
    traces_sample_rate=1.0,
    profiles_sample_rate=1.0,
)
