import requests


class GithubAPI:
    def __init__(self, token):
        self.token = token
        self.headers = {
            "Accept": "application/vnd.github.v3+json",
            "Authorization": f"Bearer {self.token}",
            "X-Github-Api-Version": "2022-11-28",
        }
        self.base_url = "https://api.github.com/repos/apache/beam"

    def fetchData(self, suburl):
        url = f"{self.base_url}/{suburl}"
        response = requests.get(url, headers=self.headers)
        return response.json()
