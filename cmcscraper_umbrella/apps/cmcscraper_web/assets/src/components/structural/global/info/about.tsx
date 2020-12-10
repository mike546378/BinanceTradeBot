import React from "react";
import { Container, Row } from "react-bootstrap";

import "./about.css";
const About: React.FC = () =>(
        <Container className="about">
            <Container>
            <h2>Lockdown! The Game!</h2>
            </Container>
            <Container>
            <Row>
            <h5>The world is in Lockdown and it is your responsibility to stay at home.</h5>
            <p>You've watched all the shows you've been planning to watch, finally played all the games you own, read all your books. Now what will you do to stay sane?</p>
            </Row>
            <hr />
            <Row>
            <p>
                We were inspired to make this game by James Veitch's video by the same name.
                While his version was amazing, it wouldn't work as an actual game, so we took the concept
                and made something possibly just as good.
            </p>
            </Row>
            </Container>
        </Container>
    );

export default About;