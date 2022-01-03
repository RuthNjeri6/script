
db.createUser(
{
    user: "main",
    pwd:  "question123", 
    roles: [ { role: "readWrite", db: "bm" }]
})


checkIfSuperUserIsLoggedIn(bm:any) {
    this.AuthenticationService.userProfile$.subscribe(
      data=>{
        this.userProfile=data;
        window.location.href = `${this.href}/${bm}/${this.userProfile.username}`
      }

    )
  }

  getLoggedUserData(participantId:string): Observable<any> {
    return this.http.get(`${environment.api_url}/v1/participants/userdata/${participantId}`);
  }

  //update participant progress
  updateUserProgress(data:any): Observable<any>{
    return this.http.patch(`${environment.api_url}/v1/participants/userdata/${data?.participantId}`,data);
  }