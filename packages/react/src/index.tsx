import { DateTime } from "mono-utils";
import ReactDOM from "react-dom";

const App = () => {
  return <h1>Hello, World! {new DateTime().toISOString()}</h1>;
};

ReactDOM.render(<App />, document.getElementById("root"));
